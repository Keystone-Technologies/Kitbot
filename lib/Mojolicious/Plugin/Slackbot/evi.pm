package Mojolicious::Plugin::Slackbot::evi;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

#mojo get https://evi.com/q/what_is_the_age_of_obama 'div.tk_common a' text 
#mojo get https://evi.com/q/what_is_the_age_of_obama 'div.single_answer div.tk_object h3.tk_text' text
sub render {
  my $self = shift;
  return unless $ip;
  $self->self->ua->get("http://ipinfo.io/$ip/json" => sub {
    my ($ua, $tx) = @_;
    my $org = $tx->res->json->{org} || 'Unknown';
    $self->self->render(json => {text => "$ip belongs to $org"});
  });
}

1;
