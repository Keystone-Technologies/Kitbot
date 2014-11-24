package Mojolicious::Plugin::Slackbot::Base;
use Mojo::Base -base;
use Mojo::JSON 'j';
use Mojo::Redis2;

has 'c';
has responses => sub { [] };
has redis => sub { shift->{redis} ||= Mojo::Redis2->new };
has me => sub { ((split /::/, ref shift)[-1]) };
has params => sub { [qw/token team_id channel_id channel_name timestamp user_id user_name text trigger_word/] };
has token => sub { shift->app->param('token') };
has team_id => sub { shift->c->param('team_id') };
has channel_id => sub { shift->c->param('channel_id') };
has channel_name => sub { shift->c->param('channel_name') };
has timestamp => sub { shift->c->param('timestamp') };
has user_id => sub { shift->c->param('user_id') };
has user_name => sub { shift->c->param('user_name') };
has text => sub { shift->c->param('text') };
has trigger_word => sub { shift->c->param('trigger_word') };

sub triggered {
  my $self = shift;
  return unless $self->text;
  my $me = $self->me;
  my $auto = $self->redis->hget($me => 'auto') || '';
  my $triggers = $self->redis->hget($me => 'triggers') || '^$';
  $triggers = qr/$triggers/;
  my ($trigger_word) = ($self->text =~ /\b$me\b|$triggers/);
  $self->trigger_word($trigger_word);
  $self->trigger_word || $auto eq 'on';
}

sub respond { my $self = shift; push @{$self->responses}, shift; $self }

sub render {
  my $self = shift;
  my $c = $self->c;
  my $me = $self->me;
  my $tasks = $c->minion->tasks;
  foreach my $task ( grep { /^$me:/ } keys %$tasks ) {
    my $key = "$task:queue_time";
    if ( $c->redis->exists($key) ) {
      $c->redis->ltrim($key, 0, 100);
      if ( my @times = $c->redis->lrange($key, 0, -1) ) {
        my $times = 0;
        $times += $_ foreach @times;
        my $avg = $times / ($#times+1);
        $self->respond(sprintf '%s generally responds within %d seconds, %s', $task, $avg, $self->user_name) if $avg >= 0;
      }
    }
  }
  $self;
}

#curl -X POST --data-urlencode 'payload={"channel": "#general", "username":
#"webhookbot", "text": "This is posted to #general and comes from a bot
#named webhookbot.", "icon_emoji": ":ghost:"}'
#https://hooks.slack.com/services/........./........./........................
sub post {
  my ($self, $job, $channel_name, $user_name, $text) = @_;
  $job->app->log->info(sprintf "[%s:%s#%s] %s: %s", $job->task, $job->id, $channel_name, $user_name, $text);
  #$job->app->ua->post($job->app->config->{incoming} => json => {channel => $channel_name, text => $text, username => $job->config->{slackbot}->{name}, icon_emoji => 'ghost'});
}
      
1;
