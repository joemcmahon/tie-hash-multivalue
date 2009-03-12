package Tie::Hash::MultiValue;
use strict;
use Tie::Hash;
@Tie::Hash::MultiValue::ISA = qw(Tie::ExtraHash);

BEGIN {
	use vars qw ($VERSION);
	$VERSION     = 0.01;
}

=head1 NAME

Tie::Hash::MultiValue - store multiple values per key

=head1 SYNOPSIS

  use Tie::Hash::MultiValue;
  tie %hash, 'Tie::Hash::Multivalue';
  $hash{'foo'} = 'one';
  $hash{'bar'} = 'two';
  $hash{'bar'} = 'three';

  my @values  = @{$hash{'foo'}};   # @values = ('one');
  my @more    = @{$hash{'bar'}};   # @more   = ('two', 'three');
  my @nothing = $hash{'baz'};      # undefined if nothing there

  # You can save multiple values at once:
  $hash{'more'} = ('fee','fie', 'foe', 'fum');
  my @giant_words = @{$hash{'more'}};

  # You can tie an anonymous hash as well.
  my $hash = {};
  tie %$hash, 'Tie::Hash::MultiValue';
  $hash->{'sample'} = 'one';
  $hash->{'sample'} = 'two';
  # $hash->{'sample'} now contains ['one','two']

=head1 DESCRIPTION

C<Tie::Hash::Multivalue> allows you to have hashes which store their values
in anonymous arrays, appending any new value to the already-existing ones.

This means that you can store as many items as you like under a single key,
and access them all at once by accessing the value stored under the key.

=head1 USAGE

See the synopsis for a typical usage.

=head1 BUGS

None currently known.

=head1 SUPPORT

Contact the author for support.

=head1 AUTHOR

	Joe McMahon
        CPAN ID: MCMAHON
	mcmahon@ibiblio.org
	http://ibiblio.org/mcmahon

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Tie::Hash, perl(1), Perl Cookbook (1st version) recipe 13.15, program 13-5.

=head1 METHODS

This class is a subclass of C<Tie::ExtraHash>; it needs to override the 
C<TIEHASH> method to save the instance data (in $self->[1]), and the C<STORE>
method to actually save the values in an anonymous array.

=head2 TIEHASH

If the 'unique' argument is supplied, we check to see if it supplies a 
subroutine reference to be used to compare items. If it does, we store that 
reference in the object describing this tie; if not, we supply a function 
which simply uses 'eq' to test for equality.

=head3 The 'unique' function

This funtion will receive two scalar arguments. No assumption is made about
whether or not either argument is defined, nor whether these are simple
scalars or references. You can make any of these assumptions if you choose,
but you are responsible for checking your input.

You can perform whatever tests you like in your routine; you should return 
a true value if the arguments are determined to be equal, and a false one
if they are not.

=cut

sub TIEHASH {
  my $class = shift;
  my $self = [{},{}];
  push @_, undef if @_ % 2 == 1;

  my %args = @_;
  if (exists $args{'unique'}) {
    if (defined $args{'unique'} and ref $args{'unique'} eq 'CODE') {
      $self->[1]->{Unique} = $args{'unique'};
    }
    else {
      $self->[1]->{Unique} = sub { 
                                   my ($foo, $bar) = @_;
                                   $foo eq $bar;
                                 };
    }
  }
  bless $self, $class;
}

=head2 STORE

Push the value(s) supplied onto the list of values stored here. The anonymous 
array is created automatically if it doesn't yet exist.

If the 'unique' argument was supplied at the time the hash was tied, we will
use the associated function (either yours, if you supplied one; or ours, if
you didn't) and only add the item or items that are not present.

=cut

sub STORE {
  my($self, $key, @values) = @_;

  if ($self->[1]->{Unique}) {
    # The unique test is defined; check the incoming values to see if
    # any of them are unique
    local  $_;
    foreach my $item (@values) {
      next if grep {$self->[1]->{Unique}->($_, $item)} @{$self->[0]->{$key}};
      push @{$self->[0]->{$key}}, $item;
    }
  }
  else {
    push @{$self->[0]->{$key}}, @values;
  }
}

1; #this line is important and will help the module return a true value
__END__

