#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::EnsEMBL::Registry;
use Test::Most;
use Log::Log4perl qw( :levels );

BEGIN {
    Bio::EnsEMBL::Registry->load_registry_from_db(
        -host => $ENV{HTGT_ENSEMBL_HOST} || 'ens-livemirror.internal.sanger.ac.uk',
        -user => $ENV{HTGT_ENSEMBL_USER} || 'ensro'
    );
}

Log::Log4perl->easy_init( $DEBUG );

use_ok( 'HTGT::Utils::DesignFinder::Helpers', qw( butfirst butlast ) );

{
    my @foo = qw( a b c d e );

    cmp_deeply( [ butfirst( @foo ) ], [ qw( b c d e) ], 'butfirst' );

    cmp_deeply( [ butlast( @foo ) ], [ qw( a b c d ) ], 'butlast' );
}

done_testing();


sub fetch_transcript {
    my $stable_id = shift;
    
    my $ta = Bio::EnsEMBL::Registry->get_adaptor( 'mouse', 'core', 'transcript' );

    my $t = $ta->fetch_by_stable_id( $stable_id )
        or die "failed to fetch transcript $stable_id";

    return $t;
}

