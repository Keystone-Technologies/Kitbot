package Mojolicious::Plugin::Kitbot::Base;
use Mojo::Base -base;
use Mojo::Loader;
use Mojo::Log;
use Mojo::UserAgent;
use Mojo::Redis2;

use Mojolicious::Plugin::Kitbot::Bots;
use Mojolicious::Plugin::Kitbot::Channel;
use Mojolicious::Plugin::Kitbot::Users;

use Minion;

has namespace => sub { join '::', __PACKAGE__ };

has 'app';  # Mojo app
has 'mojo'; # Mojolicious Controller instance

has config => sub { my $self = shift; my $service = $self->service; $self->app->config->{services}->{$service} };
has service => sub { shift->_service };
has minion => sub { Minion->new(File => 'minion.db') };
has redis => sub { Mojo::Redis2->new };
has log => sub { Mojo::Log->new };
has ua => sub { Mojo::UserAgent->new };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->bots;
  $self;
}

has bots => sub {
  Mojolicious::Plugin::Kitbot::Bots->new(kitbot => shift);
};
has channel => sub {
  if ( $#_ == 1 ) {
    Mojolicious::Plugin::Kitbot::Channel->new(kitbot => shift, channel => shift);
  } else {
    # FAIL
  }
};
has users => sub {
  if ( $#_ == 1 ) {
    Mojolicious::Plugin::Kitbot::Users->new(kitbot => shift, user => shift);
  } elsif ( $#_ == 2 ) {
    Mojolicious::Plugin::Kitbot::Users->new(kitbot => shift, user => shift, users => shift);
  } else {
    # FAIL
  }
};
has 'message';
# What else is there to know about the environment?  There's the room and the people in it.

# THIS IS THE GUTS
# Everything else is the framework
# This is what makes it smooth and gives it that AI feel
# How to handle all this.
# REMEMBER: think of the bot as a person in the room
sub respond {
  my $self = shift;

  # Should more than one bot be able to process a message?
  # That is, you ask someone a question, should you get two different answers?
  # One person is responding appropriately, the other one gets looked at like a fool.
  # But what if the fool speaks up first, should the correct one not respond?
  # How about a "oh I've got this" method which would then cancel the first response before it gets delivered.
  # Can each bot respond with their answer and a confidence rating?
  # Then render one response: the highest rating; if a tie, take the first or random
  #$self->triggered(sub {
  #  my $b = shift;
    # Plugins: ipinfo, whois (these are 100% confidence, take the first match, then quit
  #});
  #$self->permanent(sub {
  #  my $b = shift;
    # Built-in (trigger only): global on/off, admin control
    # slack management (like what??)
    # Plugins: karma (trigger only, but not necessarily named by the plugin)
    # How can bot respond?  Think of it like a person.  It can respond with body language (confidence)
    # It can respond with an action, or with words
    # In the end, we can only communicate back to the person with words (images, whatever)
    # But this is the place to know what responses a bot is taking.  Change a permission?  Change a setting?
    # Should the bots themselves change settings?  Yes, there will be bot specific settings
    # But we also need Kitbot-level responses that can manage all the bots.  i.e. Kitbot should have priority and intercept and interject whenever it deems appropriate
    # $r = $response_obj = $self->bots->eliza->get_response # It might respond with text, or it might respond with an action, like shutting down or incrementing karma or setting permisions
    # $r->confidence # (body language) 10%?  100%?  Not sure how it'll be figured...  0% would mean use this response only if there's nothing else; no response means no response
    # $r->message    # (oral language)
  #});
  #$self->auto(sub {
  #  my $b = shift;
    # Plugins: eliza, chatbot, pandoras, evi, wolfram
  #});

  # Gotta render something...
  $self->mojo->render(text => '', status => 204);
}

sub _service { ((split /::/, __PACKAGE__)[-1]) }

1;
