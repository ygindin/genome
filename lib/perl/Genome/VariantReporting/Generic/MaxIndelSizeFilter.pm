package Genome::VariantReporting::Generic::MaxIndelSizeFilter;

use strict;
use warnings;
use Genome;

class Genome::VariantReporting::Generic::MaxIndelSizeFilter {
    is => 'Genome::VariantReporting::Framework::Component::Filter',
    has => [
        size => {
            is => "Number",
            doc => "The maximum size of an INDEL to pass",
        },
    ],
};

sub __errors__ {
    my $self = shift;

    my @errors = $self->SUPER::__errors__;
    return @errors if @errors;

    my $size = $self->size;
    if ( $size !~ /^\d+$/ ) {
        push @errors, UR::Object::Tag->create(
            type => 'error',
            properties => [qw/ size /],
            desc => "Value given ($size) is not a whole number!",
        );
    }

    return @errors;
}

sub name {
    return 'max-indel-size';
}

sub requires_experts {
    return qw/ /;
}

sub filter_entry {
    my $self = shift;
    my $entry = shift;

    my %return_values;
    for my $alt_allele ( @{$entry->{alternate_alleles}} ) {
        my $indel_length = abs( length($entry->{reference_allele}) - length($alt_allele) );
        $return_values{$alt_allele} = ( $indel_length >= $self->size ) ? 0 : 1;
    }

    return %return_values;
}

1;

