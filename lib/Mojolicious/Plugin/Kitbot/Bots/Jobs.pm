package Slackbot::Jobs;
use Mojo::Base -base;

sub post {
  my ($self, $job, $channel_name, $user_name, $text) = @_;
  $user_name ||= 'oh btw';
  $job->app->log->debug(sprintf "Posting results of %s to #%s: %s", $job->task, $channel_name, "$user_name: $text");
  if ( $channel_name ) {
    $job->app->ua->post($job->app->config->{slackbot}->{incoming} => json => {channel => '#'.$channel_name, text => "$user_name: $text", username => $job->app->config->{slackbot}->{name}, icon_emoji => 'ghost'});
  } else {
    $job->app->ua->post($job->app->config->{slackbot}->{incoming} => json => {text => "$user_name: $text", username => $job->app->config->{slackbot}->{name}, icon_emoji => 'ghost'});
  }
}

1;
