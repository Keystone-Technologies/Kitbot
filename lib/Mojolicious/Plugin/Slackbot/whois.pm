package Mojolicious::Plugin::Slackbot::whois;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Net::Whois::Raw;

sub add_tasks {
  my ($class, $me, $app) = @_;
  $app->minion->add_task($me => sub {
    my ($job, $channel_name, $user_name, $domain) = @_;
    sleep 2;
    $job->app->log->info(sprintf '[%s:%s] Performing whois for %s in %s on "%s"', $job->task, $job->id, $channel_name, $user_name, $domain);
    my ($expires) = (whois($domain) =~ /^Registrar Registration Expiration Date: (.*?)$/m);
    $class->post($job, $channel_name, $user_name, "$domain expires $expires");
  });
}

sub render {
  my $self = shift;
  $self->stamp;
  my $text = shift || $self->text;
  $text =~ s/\s*whois\s*//;
  my ($domain) = ($text =~ /(.*)/);
  return unless $domain;
  my $id = $self->app->minion->enqueue($self->me => [$self->channel_name, $self->user_name, $domain]);
  my $task = $self->app->minion->job($id)->task;
  $self->app->app->log->info("[$task] Queued $id");
  $self->app->render(text => '', status => 202);
}

1;
