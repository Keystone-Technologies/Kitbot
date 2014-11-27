package Mojolicious::Plugin::Kitbot;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader;

has namespace => __PACKAGE__;

sub register {
  my ($self, $app, $config) = @_;

  my @services = ();
  my @failed_services = ();
  my $l = Mojo::Loader->new;
  foreach my $service_module ( map { join '::', $self->namespace, $_ } keys %{$app->config->{services}} ) {
    if ( $l->load($service_module) ) {
      $app->log("Error loading $service_module");
    } else {
      $service_module->new(app => $app);
    }
  }
}

1;
