package Mojolicious::Plugin::Kitbot::Bots;
use Mojo::Base -base;
use Mojo::Loader;
use Mojo::Util 'monkey_patch';

has namespace => __PACKAGE__;

has 'kitbot';
has bots => sub { [] };

sub new {
  my $self = shift->SUPER::new(@_);

  my $l = Mojo::Loader->new;
  foreach my $bot_module ( @{$l->search($self->namespace)} ) {
    my ($bot) = ($bot_module =~ /::(\w+)$/);
    next unless $bot eq lc($bot);
    if ( $l->load($bot_module) ) {
      $app->log->error("Error loading Kitbot bot $bot");
    } else {
      monkey_patch __PACKAGE__, sub { $bot_module->new(kitbot=>$self) };
    }
  }
}

1;
