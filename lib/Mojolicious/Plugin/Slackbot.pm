package Mojolicious::Plugin::Slackbot;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader;
use Mojo::Redis2;

has namespace => join '::', __PACKAGE__;
has params => sub { [qw/token team_id channel_id channel_name timestamp user_id user_name trigger_word/] };
has bots => sub { {} };

sub register {
  my ($self, $app) = @_;

  $app->plugin(Minion => {File => 'minion.db'});
                          
  my @bots = ();
  my @failed_bots = ();
  my $l = Mojo::Loader->new;
  foreach my $module ( @{$l->search($self->namespace)} ) {
    my ($plugin) = ($module =~ /::(\w+)$/);
    next unless $plugin eq lc($plugin);
    if ( $l->load($module) ) {
      push @{$self->bots->{failed}}, $plugin;
      $app->log->error("Error loading Slackbot plugin $plugin");
    } else {
      push @{$self->bots->{loaded}}, $plugin;
      $module->can('add_tasks') and $module->add_tasks($plugin => $app);
      $app->helper("slackbot.$plugin" => sub { $module->new(app => shift) });
    }
  }

  $app->routes->post('/slackbot' => sub {
    my $c = shift;

    unless ( $app->mode eq 'development' ) {
      return $c->reply->not_found unless $c->param('token') && $c->param('token') eq $c->config->{token};
      return $c->reply->not_found if $c->param('user_name') && $c->param('user_name') eq $c->config->{slackbot}->{name};
    }
    $c->render_later;
    $c->app->log->debug("Slacking!");

    #my $text = lc($c->param('text'));
    #if ( my ($bot) = grep { $text =~ /\b$_\b/ } @bots ) {
    #  $c->param(trigger_word => $bot);
    #  if ( $text =~ /\b(hi|hello|howdy|hey|yo|on)\b/ ) {
    #    $c->slackbot->redis->set('autobot' => $bot);
    #    $c->render($c->slackbot->interp($c->slackbot->redis->hget($bot => 'awaken') || 'Hello, #$channel_name'));
    #  } elsif ( $text =~ /\b(go\s+away|shut\s+(up|it)|pipe|off)\b/ ) {
    #    $c->slackbot->redis->set('autobot' => '');
    #    $c->render($c->slackbot->interp($c->slackbot->redis->hget($bot => 'snooze') || 'Good-bye, #$channel_name'));
    #  } else {
    #    $c->slackbot->$bot->render($text);
    #  }
    #} elsif ( my $autobot = $c->slackbot->redis->get('autobot') ) {
    #  $c->slackbot->$autobot->render($text);
    #} elsif ( my ($failed_bot) = grep { $text =~ /\b$_\b/ } @failed_bots ) {
    #  $c->app->log->debug(sprintf 'User %s in %s said "%s" and the %s bot needed to process it failed.', (map { $c->param($_) } qw/user_name channel_name text/), $failed_bot);
    #  $c->render(text => '', status => 204);
    #} else {
    #  $c->app->log->debug(sprintf 'User %s in %s said "%s" and I don\'t know what to do with that.', map { $c->param($_) } qw/user_name channel_name text/);
    # $c->render(text => '', status => 204);
    #}

    my ($passed, $rendered, $now, $jobs, $later) = $self->process($c);
    if ( @$now ) {
      $c->render(json => {text => join "\n", map { $_->[1] } @$now}) unless @$rendered;
    } elsif ( @$jobs ) {
      $c->render(text => '', status => 202) unless @$rendered;
    } elsif ( !@$now && !@$later && !@$jobs ) {
      if ( @$passed ) {
        $c->render(text => '', status => 204) unless @$rendered;
      } else {
        $c->render(text => '', status => 200) unless @$rendered;
      }
    }
  });

  #$app->helper('slackbot.redis' => sub { shift->stash->{redis} ||= Mojo::Redis2->new });

}

sub process {
  my ($self, $c) = @_;
  my @processed = ();
  foreach my $bot ( @{$self->bots->{loaded}} ) {
    warn "Checking $bot\n";
    next unless $c->slackbot->$bot->triggered;
    warn "Processing $bot\n";
    push @processed, [$bot => $c->slackbot->$bot->process];
  }
  my @passed = grep { !ref $_->[1] && not defined $_->[1] } @processed;
  my @rendered = grep { !ref $_->[1] && ($_->[1] eq '0' || $_->[1] eq '1') } @processed;
  my @now = grep { !ref $_->[1] && ($_->[1] ne '0' && $_->[1] ne '1') } @processed;
  my @jobs = grep { ref $_->[1] eq 'Minion::Job' } @processed;
  my @later = grep { ref $_->[1] && ref $_->[1] ne 'Minion::Job' } @processed;
  if ( $c->app->mode eq 'development' ) {
    $c->app->log->debug(sprintf 'Rendering %s now and %s later and queued %s; %s passed and %s have already rendered', $#now+1, $#later+1, $#jobs+1, $#passed+1, $#rendered+1);
    $c->app->log->debug(sprintf '  Passed:   %s', join ', ', map { $_->[0] } @passed);
    $c->app->log->debug(sprintf '  Rendered: %s', join ', ', map { $_->[0] } @rendered);
    $c->app->log->debug(sprintf '  Now:      %s', join ', ', map { $_->[0] } @now);
    $c->app->log->debug(sprintf '  Jobs:     %s', join ', ', map { $_->[0] } @jobs);
    $c->app->log->debug(sprintf '  Later:    %s', join ', ', map { $_->[0] } @later);
  }
  return \@passed, \@rendered, \@now, \@jobs, \@later;
}

#$app->helper('slackbot.interp' => \&_interp);
sub _interp {
  my ($c, $text) = @_;
  my @values = split /\n/, $text;
  $text = $values[int(rand($#values))];
  foreach my $param ( $c->param ) {
    local $_ = $c->param($param);
    $text =~ s/\$$param/$_/g;
  }
  $c->render(json => {text => $text});
}

1;
