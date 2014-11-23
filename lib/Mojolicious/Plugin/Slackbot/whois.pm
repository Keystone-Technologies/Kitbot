package Mojolicious::Plugin::Slackbot::whois;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Net::Whois::Raw;

sub add_tasks {
  my ($class, $me, $app) = @_;
  $app->minion->add_task($me => sub {
    my ($job, $channel_name, $user_name, $text) = @_;
    $text =~ s/\s*whois\s*//;
    my ($domain) = ($text =~ /(.*)/);
    $job->app->log->info(sprintf '[%s:%s] Performing whois for %s in %s on "%s"', $job->task, $job->id, $channel_name, $user_name, $domain);
    sleep 2;
    my ($expires) = (whois($domain) =~ /^Registrar Registration Expiration Date: (.*?)$/m);
    $class->post($job, $channel_name, $user_name, "$domain expires $expires");
  });
}

1;
