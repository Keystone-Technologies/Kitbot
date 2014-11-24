package Mojolicious::Plugin::Slackbot::whois;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Net::Whois::Raw;

sub add_tasks {
  my ($self, $me, $app) = @_;
  $app->minion->add_task("$me:expires" => sub {
    my ($job, $channel_name, $user_name, $text) = @_;
    my $timer = time;
    $text =~ s/\s*whois\s*//;
    my ($domain) = ($text =~ /<[^\|]+\|([^>]+)>/);
    return unless $domain;
    $job->app->log->debug(sprintf 'Running %s for %s in %s on "%s"', $job->task, $user_name, $channel_name, $domain);
    my ($expires) = (whois($domain) =~ /^Registrar Registration Expiration Date: (.*?)$/m);
    $expires ||= 'unknown';
    $self->post($job, $channel_name, $user_name, "$domain expiration is $expires");
    $app->job_timer($me => $timer);
  });
}

1;
