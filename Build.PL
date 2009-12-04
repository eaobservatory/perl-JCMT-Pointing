#!perl

use strict;
use warnings;
use Module::Build;

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'JCMT::Pointing',
   license  => 'gpl',
   dist_abstract => 'Hnadle JCMT pointing data',
   dist_author => 'Tim Jenness <t.jenness@jach.hawaii.edu>',
   dist_version => '0.10',
   build_requires => {
                      'Test::More' => 0,
                     },
   requires => {
                'Astro::Coords::Offset' => 0,
                NDF => 1.49,
               },
  );

$build->create_build_script;
