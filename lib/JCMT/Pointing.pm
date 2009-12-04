package JCMT::Pointing;

=head1 NAME

JCMT::Pointing - Handle JCMT pointing data

=head1 SYNOPSIS

  use JCMT::Pointing;

  my $pnt = JCMT::Pointing->new();

  my $fit = JCMT::Pointing::Fit->new( %fit );
  $pnt->write_fit( $file, $fit1, $fit2 );

=head1 DESCRIPTION

A wrapper class for JCMT pointing operations.

=cut

use strict;
use warnings;
use Carp;

our $VERSION = '0.10';

use NDF 1.49;
use JCMT::Pointing::Fit;
use Astro::Coords::Offset;

# These are the names of extensions
use constant POINT_EXT_NAME => "JCMT_POINTING";
use constant POINT_EXT_TYPE => "MM_POINTING";
use constant FIT_NAME => "FIT";
use constant FIT_TYPE => "POINTING_FITS";


=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new JCMT::Pointing object.

 $pnt = JCMT::Pointing->new();

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # currently has not information
  return bless { }, $class;
}

=back

=head1 GENERAL METHODS

=over

=item B<write_fit_to_datafile>

Write pointing fits to the supplied NDF file.

  $pnt->write_fit_to_datafile( $ndf, @fits );

Where "@fits" is an array of JCMT::Pointing::Fit objects.

Can croak on error.

=cut

sub write_fit_to_datafile {
  my $self = shift;
  my $file = shift;
  croak "Must define a data file name" unless defined $file;
  my @fits = @_;
  croak "Must supply at least one fit" unless @fits;

  my $status = &NDF::SAI__OK();
  err_begin( $status );
  ndf_begin( );
  ndf_open( &NDF::DAT__ROOT(), $file, "UPDATE", "OLD", my $indf,
            my $place, $status );

  # Remove pre-existing extension (if we start putting
  # more in the extension this may not be a good thing)
  ndf_xstat( $indf, POINT_EXT_NAME, my $there, $status );
  ndf_xdel( $indf, POINT_EXT_NAME, $status ) if $there;

  # create new one
  my @dims = ( 1 );
  ndf_xnew( $indf, POINT_EXT_NAME, POINT_EXT_TYPE, 0, @dims, my $ploc, $status );

  # and create an array of structures for the fit
  @dims = ( scalar @fits );
  my $ndims = 1;
  if ( @fits == 1 ) {
    $ndims = 0;
  }
  dat_new( $ploc, FIT_NAME, FIT_TYPE, $ndims, @dims, $status );

  # find the structure
  dat_find( $ploc, FIT_NAME, my $floc, $status );

  # Write the information
  if (@fits == 1) {
    $self->_fill_fit_structure( $floc, $fits[0], $status );
  } else {
    # need a cell
#    print Dumper(\@fits);

    for my $i ( 1.. @fits ) {
      # need to map a cell
      my @sub = ( $i );
      dat_cell( $floc, $ndims, @sub, my $cloc, $status );
      $self->_fill_fit_structure( $cloc, $fits[$i-1], $status );
      dat_annul($cloc, $status);
    }
  }

  # cleanup
  dat_annul($floc, $status);
  dat_annul($ploc, $status);
  ndf_annul($indf, $status);
  ndf_end($status);

  if ($status != &NDF::SAI__OK()) {
    my $errstr = err_flush_to_string( $status );
    err_annul( $status );
    croak "$errstr";
  }
  err_annul($status);

}

sub _fill_fit_structure {
  my $self = shift;
  my $loc = shift;
  my $fit = shift;
  return if $_[0] != &NDF::SAI__OK;

  my $offset = $fit->offset;
  my $system = $offset->system;
  dat_new0c( $loc, "SYSTEM", length($system), $_[0] );
  cmp_put0c( $loc, "SYSTEM", $system, $_[0] );

  dat_new1d( $loc, "OFFSET", 2, $_[0] );
  my @offsets = map { $_->arcsec } $offset->offsets;
  cmp_put1c( $loc, "OFFSET", 2, @offsets, $_[0] );

  my $label = $fit->label;
  dat_new0c( $loc, "LABEL", length($label), $_[0] );
  cmp_put0c( $loc, "LABEL", $label, $_[0] );

}

=item B<read_fit_from_datafile>

Read the FIT structure from a data file and return it
as a list of JCMT::Pointing::Fit objects. Returns empty
list if no fit is available.

  @fits = $pnt->read_fit_from_datafile( $file );

=cut

sub read_fit_from_datafile {
  my $self = shift;
  my $file = shift;

  my @fits;

  my $status = &NDF::SAI__OK();
  err_begin( $status );
  ndf_begin( );
  ndf_find( &NDF::DAT__ROOT(), $file, my $indf, $status );

  # see if we have an extension
  ndf_xstat( $indf, POINT_EXT_NAME, my $there, $status );
  if ($there) {

    # get a locator to it
    ndf_xloc( $indf, POINT_EXT_NAME, "READ", my $xloc, $status );

    dat_there( $xloc, FIT_NAME, $there, $status );

    if ( $there ) {
      # see if we have an array
      cmp_size( $xloc, FIT_NAME, my $size, $status );

      # get the locator to the structure
      dat_find( $xloc, FIT_NAME, my $floc, $status );

      if ($size == 1) {
        @fits = $self->_read_fit_structure( $floc, $status );
      } else {
        for my $i ( 1..$size ) {
          my @sub = ( $i );
          dat_cell( $floc,1, @sub, my $cloc, $status );
          push( @fits, $self->_read_fit_structure( $cloc, $status ));
          dat_annul($cloc, $status);
        }
      }
      dat_annul($floc, $status);
    }

    dat_annul( $xloc, $status );

  }

  # close file
  ndf_annul( $indf, $status );

  ndf_end($status);

  if ($status != &NDF::SAI__OK()) {
    my $errstr = err_flush_to_string( $status );
    err_annul( $status );
    croak "$errstr";
  }
  err_annul($status);

  return @fits;
}

sub _read_fit_structure {
  my $self = shift;
  my $floc = shift;

  cmp_get0c( $floc, "SYSTEM", my $system, $_[0]);
  cmp_get0c( $floc, "LABEL", my $label, $_[0]);
  my @offsets;
  cmp_get1d( $floc, "OFFSET", 2, @offsets, my $nel, $_[0]);

  if ($_[0] == &NDF::SAI__OK() ) {
    my $offset = Astro::Coords::Offset->new( @offsets,
                                             units => "arcsec",
                                             system => $system);
    return JCMT::Pointing::Fit->new( label => $label,
                                     offset => $offset );
  }
  return;
}

=back

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

Copyright (C) 2009 Science and Technology Facilities Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307, USA

=cut

1;
