package Mojolicious::Plugin::Slackbot::Base;
use Mojo::Base -base;
use Mojo::JSON 'j';

has 'app';
has me => sub { ((split /::/, ref shift)[-1]) };
has params => sub { [qw/token team_id channel_id channel_name timestamp user_id user_name text trigger_word/] };
has token => sub { shift->app->param('text') };
has team_id => sub { shift->app->param('team_id') };
has channel_id => sub { shift->app->param('channel_id') };
has channel_name => sub { shift->app->param('channel_name') };
has timestamp => sub { shift->app->param('timestamp') };
has user_id => sub { shift->app->param('user_id') };
has user_name => sub { shift->app->param('user_name') };
has text => sub { shift->app->param('text') };
has trigger_word => sub { shift->app->param('trigger_word') };

sub stamp {
  my $self = shift;
  $self->app->app->log->info(sprintf "[%s] Rendering %s in #%s to %s", $self->me, ($self->trigger_word?'response':'auto-response'), $self->channel_name, $self->user_name);
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
