package Mojolicious::Plugin::Slackbot::ipinfo;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Mojo::UserAgent;

has ua => sub { Mojo::UserAgent->new };

sub render {
  my $self = shift;
  my $c = $self->c;
  my ($ip) = ($self->text =~ /([\d+\.]+)/);
  return unless $ip;
  my $tx = $self->ua->get("http://ipinfo.io/$ip/json");
  my $org = $tx->res->json->{org} || 'Unknown';
  $self->respond("$ip belongs to $org");
}

1;
