#!perl

use Test::More tests => 17;
use File::Spec;
use File::Copy;

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

# We are writing to a test file so we copy the reference
# to avoid continually updating the original file


my $infile = File::Spec->catfile( "t", "pnttest.sdf" );
my $testfile = File::Spec->catfile( "t", "testfile.sdf" );
copy( $infile, $testfile ) or die "Copy of test file failed: $!";
END { unlink $testfile; }

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

# Append a fit.
my @newfit;
$newfit[0] = JCMT::Pointing::Fit->new( label => "psf",
                                       offset => Astro::Coords::Offset->new( 2.0, 1.5,
                                                                             system => 'AZEL' ) );
$pnt->append_fit_to_datafile( $testfile, @newfit );
my @newfits = $pnt->read_fit_from_datafile( $testfile );
is( scalar( @newfits ), 2, "Count number of fits after appending one" );

# Overwrite a fit.
$newfit[0] = JCMT::Pointing::Fit->new( label => "centroid",
                                       offset => Astro::Coords::Offset->new( -0.2, 2.3,
                                                                             system => 'AZEL' ) );
$pnt->append_fit_to_datafile( $testfile, @newfit );
@newfits = $pnt->read_fit_from_datafile( $testfile );
is( scalar( @newfits ), 2, "Count number of fits after overwriting one" );
is( $newfits[0]->offset->xoffset, $newfit[0]->offset->xoffset, "Check X offset" );
is( $newfits[0]->offset->yoffset, $newfit[0]->offset->yoffset, "Check X offset" );
is( $newfits[0]->label, "centroid", "Check overwritten label" );

