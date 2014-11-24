package Mojolicious::Plugin::Slackbot::evi;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

#mojo get https://evi.com/q/what_is_the_age_of_obama 'div.tk_common a' text 
#mojo get https://evi.com/q/what_is_the_age_of_obama 'div.single_answer div.tk_object h3.tk_text' text
sub render {
  my $self = shift;
  return unless my $q = $self->text;
  $q =~ s/\W*evi\W*//g;
  $q =~ s/\s+/_/g;
  my $tx = $self->c->ua->get("https://evi.com/q/$q");
  my $answer;
  if ( $answer = $tx->res->dom->at('div.single_answer div.tk_object h3.tk_text') ) {
    $answer = $answer->text;
  } elsif ( $answer = $tx->res->dom->at('div.tk_common a') ) {
    $answer = $answer->text;
  } else {
    if ( 1 ) {
      return;
    else {
      $answer = 'Unknown';
    }
  }
  $self->respond(sprintf '%s @%s', $answer, $self->user_name);
}

1;
