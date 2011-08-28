package Mojolicious::Plugin::MountPSGI;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::MountPSGI::Proxy;


our $VERSION = '0.01';

sub register {
  my ($self, $app, $conf) = @_;

  # Extract host and path
  my $prefix = (keys %$conf)[0];
  my ($host, $path);
  if ($prefix =~ /^(\*\.)?([^\/]+)(\/.*)?$/) {
    $host = quotemeta $2;
    $host = "(?:.*\\.)?$host" if $1;
    $path = $3;
    $path = '/' unless defined $path;
    $host = qr/^$host$/i;
  }
  else { $path = $prefix }

  # Generate route
  my $route =
    $app->routes->route($path)
    ->detour(app => Mojolicious::Plugin::MountPSGI::Proxy->new(script=>$conf->{$prefix}));
  $route->over(host => $host) if $host;

  return $route;
}


1;
__END__

=head1 NAME

Mojolicious::Plugin::MountPSGI - Mount PSGI apps

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('MountPSGI', { '/', => 'ext/MyApp/app.psgi'});

  # Mojolicious::Lite
  plugin 'MountPSGI', { '/', => 'ext/MyApp/app.psgi' };

=head1 DESCRIPTION

L<Mojolicious::Plugin::MountPSGI> lets you mount any PSGI app
inside a Mojolicious app. For instance you could use this to
deploy your PSGI app under hypnotoad, or to include a PSGI
app inside a path inside your Mojo app.

=head1 METHODS

L<Mojolicious::Plugin::MountPSGI> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
