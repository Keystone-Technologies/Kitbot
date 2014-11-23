package Mojolicious::Plugin::Slackbot::eliza;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Chatbot::Eliza;

has 'eliza' => sub { Chatbot::Eliza->new };

sub render {
  my $self = shift->SUPER::render(@_);
  $self->self->render(json => {text => $self->eliza->transform($self->text)});
}

1;
