#!perl

use Test::More tests => 12;
use File::Spec;

use_ok( "JCMT::Pointing::Fit" );
use_ok( "JCMT::Pointing" );

use_ok( "Astro::Coords::Offset" );

my @fit;
$fit[0] = JCMT::Pointing::Fit->new ( label => "centroid",
                                     offset => Astro::Coords::Offset->new( 3.4, -5,
                                                                           system => "AZEL" ) );
$fit[1] = JCMT::Pointing::Fit->new ( label => "beamfit",
                                     offset => Astro::Coords::Offset->new( 0, 2.3,
                                                                           system => "J2000" ) );

isa_ok( $fit[0], "JCMT::Pointing::Fit" );
isa_ok( $fit[1], "JCMT::Pointing::Fit" );
isa_ok( $fit[0]->offset, "Astro::Coords::Offset" );
isa_ok( $fit[1]->offset, "Astro::Coords::Offset" );

my $pnt = JCMT::Pointing->new();

my $testfile = File::Spec->catfile( "t", "pnttest.sdf" );
$pnt->write_fit_to_datafile( $testfile, @fit );


# read them back
my @fits = $pnt->read_fit_from_datafile( $testfile );

is( scalar(@fits), scalar(@fit), "Count number of fits located");
is( $fits[1]->label, $fit[1]->label, "Check label");

my $offa0 = $fit[0]->offset;
my $offb0 = $fits[0]->offset;

is( $offa0->xoffset, $offb0->xoffset, "Check X offset");
is( $offa0->yoffset, $offb0->yoffset, "Check Y offset");


# Write a single one
$pnt->write_fit_to_datafile( $testfile, $fit[0] );
@fits = $pnt->read_fit_from_datafile( $testfile );
is( scalar(@fits), 1, "Count number of fits second time around");
