package Mojolicious::Plugin::Slackbot::eliza;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

use Chatbot::Eliza;

has 'eliza' => sub { Chatbot::Eliza->new };

sub render {
  my $self = shift;
  $self->respond($self->eliza->transform($self->text));
}

1;
