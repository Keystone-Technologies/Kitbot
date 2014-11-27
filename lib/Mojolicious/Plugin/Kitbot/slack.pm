package Mojolicious::Plugin::Kitbot::slack;
use Mojo::Base 'Mojolicious::Plugin::Kitbot::Base'; # A bunch of methods available here

sub new {
  my $self = shift->SUPER::new(@_); # Calls ->bots which calls ->add_tasks, so it's all good

  my $app = $self->app;

  # Any other plugins?
  # Any other helpers?

  $app->routes->post('/slack' => sub {
    $self->mojo(shift);
    my $c = $self->mojo;

    ##################################
    # Authorization to continue
    warn Data::Dumper::Dumper({map { $_ => $c->param($_) } $c->param}) if $app->mode eq 'development';
#    return $c->render(status => 401, text => '') unless $app->mode eq 'development' || ($c->param('token') && $c->param('token') eq $self->config->{token});
#    return $c->render(status => 204, text => '') if $c->param('user_name') && ($c->param('user_name') eq $self->config->{name} || $c->param('user_name') eq 'slackbot');

    # Convert all the provided parameters into the 3 objects that Kitbot understand and supports
    $self->channel($c->param('channel_name'));
    $self->users($c->param('user_name'));
    $self->message($c->param('text'));

    # What else do you want to do?
    # ...
    ##################################

    # Respond in some way.  Go thru all bot options.
    $self->respond; # All services should do this, but everything else in this package is unique to this service
  });

  # Any other routes to handle?
  #$app->routes->post('/slack/2' => sub {
  #});
}

1;
