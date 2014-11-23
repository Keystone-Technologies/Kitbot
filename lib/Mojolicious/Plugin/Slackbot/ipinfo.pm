package Mojolicious::Plugin::Slackbot::ipinfo;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

sub process {
  my $self = shift;
  my ($ip) = ($self->text =~ /([\d+\.]+)/);
  return unless $ip;
  $self->app->ua->get("http://ipinfo.io/$ip/json" => sub {
    my ($ua, $tx) = @_;
    my $org = $tx->res->json->{org} || 'Unknown';
    $self->app->render(json => {text => "$ip belongs to $org"});
  });
  $self;
}

1;
