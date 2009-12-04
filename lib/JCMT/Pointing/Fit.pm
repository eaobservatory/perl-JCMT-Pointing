package JCMT::Pointing::Fit;

=head1 NAME

JCMT::Pointing::Fit - Fit results for a pointing

=head1 SYNOPSIS

  use JCMT::Pointing::Fit;
  $fit = JCMT::Pointing::Fit->new( %fit );
  $offset = $fit->offset();

=head1 DESCRIPTION

Contains information of pointing offsets for a particular observation.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.10';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new fit object. Takes hash arguments corresponding to the
supported accessor methods.

  $fit = JCMT::Pointing::Fit->new( label => "centroid",
                                   offset => $offset );

The object is immutable so both "label" and "offset" keys
must be present.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  my $f = bless {
                 Offset => undef,
                 Label => undef,
                }, $class;

  for my $key ( qw/ label offset/ ) {
    if (exists $args{$key}) {
      my $method = "_store_".$key;
      $f->$method( $args{$key} );
    } else {
      carp "Key $key not provided to constructor";
    }
  }

  return $f;
}

=back

=head2 Accessors

=over 4

=item B<label>

Label associated with the fit. Usually the name of the application that generated
the offset.

  $label = $fit->label;

=cut

sub label {
  my $self = shift;
  return $self->{Label};
}

sub _store_label {
  my $self = shift;
  if (@_ && defined $_[0]) {
    $self->{Label} = shift;
  } else {
    croak "Trying to set label without providing a value";
  }
}

=item B<offset>

Returns the C<Astro::Coords::Offset> object containing the fitted pointing
offset and the coordinate system.

  $offset = $fit->offset();

=cut

sub offset {
  my $self = shift;
  return $self->{Offset};
}

sub _store_offset {
  my $self = shift;
  if (@_ && defined $_[0]) {
    my $value = shift;
    if (UNIVERSAL::isa( $value, "Astro::Coords::Offset") ) {
      $self->{Offset} = $value;
    } else {
      croak "Must provide an Astro::Coords::Offset";
    }
  } else {
    croak "Trying to set offset without providing a value";
  }

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
