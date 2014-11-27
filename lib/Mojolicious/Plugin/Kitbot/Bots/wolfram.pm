package Mojolicious::Plugin::Slackbot::wolfram;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

#https://api.wolframalpha.com/v2/query?input=who&appid=xxx' 'pod[title="Result"] plaintext' text

has key => sub { shift->c->config->{slackbot}->{plugins}->{wolfram}->{key} };

sub render {
  my $self = shift;
  return $self unless my $q = $self->text;
  $q =~ s/\W*wolfram\W*//g;
  $q =~ s/\s+/+/g;
  my $tx = $self->c->ua->get(sprintf "https://api.wolframalpha.com/v2/query?input=%s&appid=%s", $q, $self->key);
  $self->c->app->app->log->info(sprintf "%s:\n%s", $q, $tx->res->dom);
  my $answer;
  if ( $answer = $tx->res->dom->at('pod[title="Result"] plaintext') ) {
    $answer = $answer->text;
  } else {
    if ( 1 ) {
      return $self;
    } else {
      $answer = 'Unknown';
    }
  }
  #$self->c->app->app->log->info(sprintf '%s %s @%s', $q, $answer, $self->user_name);
  $self->respond(sprintf '%s @%s', $answer, $self->user_name);
}

1;
