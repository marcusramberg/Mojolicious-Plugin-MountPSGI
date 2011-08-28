#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::MountPSGI',
  VERSION_FROM => 'lib/Mojolicious/Plugin/MountPSGI.pm',
  AUTHOR       => '<Marcus Ramberg <mramberg@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '1.80',PSGI=>undef},
  test         => {TESTS => 't/*.t'}
);
