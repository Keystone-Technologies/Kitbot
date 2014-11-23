package Mojolicious::Plugin::Slackbot::Base;
use Mojo::Base -base;
use Mojo::JSON 'j';
use Mojo::Redis2;

has 'app';
has redis => sub { shift->{redis} ||= Mojo::Redis2->new };
has me => sub { ((split /::/, ref shift)[-1]) };
has params => sub { [qw/token team_id channel_id channel_name timestamp user_id user_name text trigger_word/] };
has token => sub { shift->app->param('token') || '' };
has team_id => sub { shift->app->param('team_id') || '' };
has channel_id => sub { shift->app->param('channel_id') || '' };
has channel_name => sub { shift->app->param('channel_name') || '[no_channel]' };
has timestamp => sub { shift->app->param('timestamp') || '' };
has user_id => sub { shift->app->param('user_id') || '' };
has user_name => sub { shift->app->param('user_name') || '[no_user]' };
has text => sub { shift->app->param('text') || '' };
has trigger_word => sub { shift->app->param('trigger_word') || '' };

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

sub process {
  my $self = shift;
  $self->app->app->log->info(sprintf "[%s] Queueing %s in #%s to %s", $self->me, ($self->trigger_word?'response':'auto-response'), $self->channel_name, $self->user_name);
  $self->app->minion->job($self->app->minion->enqueue($self->me => [$self->channel_name, $self->user_name, shift || $self->text]));
}
                    
#curl -X POST --data-urlencode 'payload={"channel": "#general", "username":
#"webhookbot", "text": "This is posted to #general and comes from a bot
#named webhookbot.", "icon_emoji": ":ghost:"}'
#https://hooks.slack.com/services/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
sub post {
  my ($class, $job, $channel_name, $user_name, $text) = @_;
  my $task = $job->task;
  my $id = $job->id;
  $job->app->log->info("[$task:$id#$channel_name] $user_name: $text");
  #$job->ua->post("https://hooks.slack.com/services/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" => json => {channel => $channel, text => $text, username => $job->config->{slackbot}->{name}, icon_emoji => 'ghost'});
}
      
1;
