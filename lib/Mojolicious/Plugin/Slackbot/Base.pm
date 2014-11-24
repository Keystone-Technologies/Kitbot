package Mojolicious::Plugin::Slackbot::Base;
use Mojo::Base -base;
use Mojo::JSON 'j';
use Mojo::Redis2;

has 'c';
has responses => sub { [] };
has redis => sub { shift->{redis} ||= Mojo::Redis2->new };
has me => sub { ((split /::/, ref shift)[-1]) };
has params => sub { [qw/token team_id channel_id channel_name timestamp user_id user_name text trigger_word/] };
sub token { shift->c->param('token') }
sub team_id { shift->c->param('team_id') }
sub channel_id { shift->c->param('channel_id') }
sub channel_name { shift->c->param('channel_name') }
sub timestamp { shift->c->param('timestamp') }
sub user_id { shift->c->param('user_id') }
sub user_name { shift->c->param('user_name') }
sub text { shift->c->param('text') }
has trigger_word => sub { shift->c->param('trigger_word') };

sub triggered {
  my $self = shift;
  return unless $self->text;
  my $me = $self->me;
  my $auto = $self->redis->hget($me => 'auto') || '';
  my $triggers = $self->redis->hget($me => 'triggers') || '^$';
  $triggers = qr/$triggers/;
  my ($trigger_word) = ($self->text =~ /(\b$me\b|$triggers)/);
  $self->trigger_word($trigger_word);
  $self->trigger_word || $auto eq 'on';
}

sub respond { my $self = shift; push @{$self->responses}, shift; $self }

sub render {
  my $self = shift;
  my $me = $self->me;
  my $tasks = $self->c->minion->tasks;
  foreach my $task ( grep { /^$me:/ } keys %$tasks ) {
    my $key = "$task:queue_time";
    if ( $self->redis->exists($key) ) {
      $self->redis->ltrim($key, 0, 100);
      if ( my @times = $self->redis->lrange($key, 0, -1) ) {
        my $times = 0;
        $times += $_ foreach @times;
        my $avg = $times / ($#times+1);
        $self->respond(sprintf '%s generally responds within %d seconds, %s', $task, $avg, $self->user_name) if $avg >= 0;
      }
    }
  }
  $self;
}

sub post {
  my ($self, $job, $channel_name, $user_name, $text) = @_;
  $user_name ||= 'oh btw';
  $job->app->log->info(sprintf "Posting results of %s to #%s: %s", $job->task, $channel_name, "$user_name: $text");
  if ( $channel_name ) {
    $job->app->ua->post($job->app->config->{slackbot}->{incoming} => json => {channel => '#'.$channel_name, text => "$user_name: $text", username => $job->app->config->{slackbot}->{name}, icon_emoji => 'ghost'});
  } else {
    $job->app->ua->post($job->app->config->{slackbot}->{incoming} => json => {text => "$user_name: $text", username => $job->app->config->{slackbot}->{name}, icon_emoji => 'ghost'});
  }
}

1;
