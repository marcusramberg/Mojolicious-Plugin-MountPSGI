package Mojolicious::Plugin::MountPSGI::Proxy;
use Mojo::Base 'Mojo';
use Plack::Util;

has app => sub { Plack::Util::load_psgi shift->script };
has 'script';

sub handler {
  my ($self, $c) = @_;
  my $plack_env = _mojo_req_to_psgi_env($c->req);
  $plack_env->{'MOJO.CONTROLLER'} = $c;
  my $plack_res = Plack::Util::run_app $self->app, $plack_env;

  # simple (array reference) response
  if (ref $plack_res eq 'ARRAY') {
    my ($mojo_res, undef) = _psgi_res_to_mojo_res($plack_res);
    $c->tx->res($mojo_res);
    $c->rendered;
    return;
  }

  # PSGI responses must be ARRAY or CODE
  die 'PSGI response not understood'
    unless ref $plack_res eq 'CODE';

  # delayed (code reference) response
  my $responder = sub {
    my $plack_res = shift;
    my ($mojo_res, $streaming) = _psgi_res_to_mojo_res($plack_res);
    unless ($streaming) {
      $c->tx->res($mojo_res);
      $c->rendered;
      return;
    }

    die 'Streaming response not yet supported';
  };
  $plack_res->($responder);
}

sub _mojo_req_to_psgi_env {

  my $mojo_req = shift;
  my $url = $mojo_req->url;
  my $base = $url->base;
  my $body =
  Mojolicious::Plugin::MountPSGI::_PSGIInput->new($mojo_req->body);

  my %headers = %{$mojo_req->headers->to_hash};
  for my $key (keys %headers) {
    my $value = $headers{$key};
    delete $headers{$key};
    $key =~ s{-}{_};
    $headers{'HTTP_'. uc $key} = $value;
  }

  return {
    %ENV,
    %headers,
    'SERVER_PROTOCOL'   => 'HTTP/'. $mojo_req->version,
    'SERVER_NAME'       => $base->host,
    'SERVER_PORT'       => $base->port,
    'REQUEST_METHOD'    => $mojo_req->method,
    'SCRIPT_NAME'       => '',
    'PATH_INFO'         => $url->path->to_string,
    'REQUEST_URI'       => $url->to_string,
    'QUERY_STRING'      => $url->query->to_string,
    'psgi.url_scheme'   => $base->scheme,
    'psgi.multithread'  => Plack::Util::FALSE,
    'psgi.version'      => [1,1],
    'psgi.errors'       => *STDERR,
    'psgi.input'        => $body,
    'psgi.multithread'  => Plack::Util::FALSE,
    'psgi.multiprocess' => Plack::Util::TRUE,
    'psgi.run_once'     => Plack::Util::FALSE,
    # 'psgi.streaming'    => Plack::Util::TRUE,
    'psgi.streaming'    => Plack::Util::FALSE,
    'psgi.nonblocking'  => Plack::Util::FALSE,
  };
}

sub _psgi_res_to_mojo_res {
  my $psgi_res = shift;
  my $mojo_res = Mojo::Message::Response->new;
  $mojo_res->code($psgi_res->[0]);
  my $headers = $mojo_res->headers;
  while (scalar @{$psgi_res->[1]}) {
    $headers->header(shift @{$psgi_res->[1]} => shift @{$psgi_res->[1]});
  }

  $headers->remove('Content-Length'); # should be set by mojolicious later
  my $streaming = 0;

  if (@$psgi_res == 3) {
    my $asset = $mojo_res->content->asset;
    Plack::Util::foreach($psgi_res->[2], sub {$asset->add_chunk($_[0])});
  } else {
    $streaming = 1;
  }
  return ($mojo_res, $streaming);
}

package Mojolicious::Plugin::MountPSGI::_PSGIInput;
use strict;
use warnings;

    sub new {
        my ($class, $content) = @_;
        return bless [$content, 0], $class;
    }

    sub read {
        my $self = shift;
        if ($_[0] = substr($self->[0], $self->[1], $_[1])) {
            $self->[1] += $_[1];
            return 1;
        }
    }

1;
