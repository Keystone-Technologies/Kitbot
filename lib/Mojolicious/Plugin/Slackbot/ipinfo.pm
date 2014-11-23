package Mojolicious::Plugin::Slackbot::ipinfo;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

sub render {
  my $self = shift->SUPER::render(@_);
  my ($ip) = ($self->text =~ /([\d+\.]+)/);
  return unless $ip;
  $self->self->ua->get("http://ipinfo.io/$ip/json" => sub {
    my ($ua, $tx) = @_;
    my $org = $tx->res->json->{org} || 'Unknown';
    $self->self->render(json => {text => "$ip belongs to $org"});
  });
}

1;
