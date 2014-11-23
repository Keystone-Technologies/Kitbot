package Mojolicious::Plugin::Slackbot;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader;
use Mojo::Redis2;

has namespace => join '::', __PACKAGE__;

my @params = qw/token team_id channel_id channel_name timestamp user_id user_name trigger_word/;

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
      push @failed_bots, $plugin;
      $app->log->error("Error loading Slackbot plugin $plugin");
    } else {
      push @bots, $plugin;
      $module->can('add_tasks') and $module->add_tasks($plugin => $app);
      $app->helper("slackbot.$plugin" => sub { $module->new(app => shift) });
    }
  }

  $app->routes->post('/slackbot' => sub {
    my $c = shift;

    return $c->reply->not_found unless $c->slackbot->token;
    return $c->reply->not_found if $c->slackbot->self;
    $c->render_later;
    $c->app->log->debug("Slacking!");

    my $text = lc($c->param('text'));
    if ( my ($bot) = grep { $text =~ /\b$_\b/ } @bots ) {
      $c->param(trigger_word => $bot);
      if ( $text =~ /\b(hi|hello|howdy|hey|yo|on)\b/ ) {
        $c->slackbot->redis->set('autobot' => $bot);
        $c->render($c->slackbot->interp($c->slackbot->redis->hget($bot => 'awaken') || 'Hello, #$channel_name'));
      } elsif ( $text =~ /\b(go\s+away|shut\s+(up|it)|pipe|off)\b/ ) {
        $c->slackbot->redis->set('autobot' => '');
        $c->render($c->slackbot->interp($c->slackbot->redis->hget($bot => 'snooze') || 'Good-bye, #$channel_name'));
      } else {
        $c->slackbot->$bot->render($text);
      }
    } elsif ( my $autobot = $c->slackbot->redis->get('autobot') ) {
      $c->slackbot->$autobot->render($text);
    } elsif ( my ($failed_bot) = grep { $text =~ /\b$_\b/ } @failed_bots ) {
      $c->app->log->debug(sprintf 'User %s in %s said "%s" and the %s bot needed to process it failed.', (map { $c->param($_) } qw/user_name channel_name text/), $failed_bot);
      $c->render(text => '', status => 204);
    } else {
      $c->app->log->debug(sprintf 'User %s in %s said "%s" and I don\'t know what to do with that.', map { $c->param($_) } qw/user_name channel_name text/);
      $c->render(text => '', status => 204);
    }
  });

  $app->helper('slackbot.token' => \&_token);
  $app->helper('slackbot.self' => \&_self);
  $app->helper('slackbot.interp' => \&_interp);
  $app->helper('slackbot.redis' => sub { shift->stash->{redis} ||= Mojo::Redis2->new });

}

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

sub _token {
  my $c = shift;
  return 1 if $c->param('token') && $c->param('token') eq $c->config->{token};
}

sub _self {
  my $c = shift;
  return 1 if $c->param('user_name') && $c->param('user_name') eq $c->config->{slackbot}->{name};
}

1;
