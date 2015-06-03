package Mojolicious::Plugin::MountPSGI;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::MountPSGI::Proxy;


our $VERSION = '0.04';

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

  my $proxy;
  my $psgi = $conf->{$prefix};
  if (ref $psgi) {
    $proxy = Mojolicious::Plugin::MountPSGI::Proxy->new(app => $psgi);
  } else {
    unless (-r $psgi) {
      my $abs = $app->home->rel_file($psgi);
      $psgi = $abs if -r $abs;
    }
    $proxy = Mojolicious::Plugin::MountPSGI::Proxy->new(script => $psgi);
  }

  # Generate route
  my $route = $app->routes->route($path)->detour(app => $proxy);
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

The key given is the route under which to mount the app. The
value is either a PSGI application or a string which resolves
to an instance via L<Plack::Util/load_psgi>.

=head1 METHODS

L<Mojolicious::Plugin::MountPSGI> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT

Most of this module was assembled from the Mojo mount plugin and the
Mojolicious-Plugin-PlackMiddleware plugin. Copyright on that code belongs
to the authors.

The remainder is (C) 2011-2015 Marcus Ramberg

=head1 LICENSE

Licensed under the same terms as Perl itself.

=cut
