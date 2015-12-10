#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious;

use Test::More;
use Test::Mojo;

my $app1 = Mojolicious->new;
$app1->plugin(MountPSGI => { '/mount' => 't/script/path.psgi' });

my $app2 = Mojolicious->new;
$app2->plugin(MountPSGI => { '/mount' => 't/script/path.psgi', rewrite => 1 });

my $t1 = Test::Mojo->new($app1);
$t1->get_ok('/mount')
  ->status_is(200)
  ->json_is('/PATH_INFO' => '/mount')
  ->json_is('/SCRIPT_NAME' => '');

my $t2 = Test::Mojo->new($app2);
$t2->get_ok('/mount')
  ->status_is(200)
  ->json_is('/PATH_INFO' => '/')
  ->json_is('/SCRIPT_NAME' => '/mount');

done_testing;

