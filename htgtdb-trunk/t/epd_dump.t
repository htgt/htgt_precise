#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
}

use Test::More;
use HTGT::DBFactory;

{
    my $indel  = qr/(Del|Ins)/;
    my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

    sub validate_design_type_assignment {
        my ( $pattern, $expected ) = @_;
        my $result =
          $schema->resultset('HTGTDB::Result::EPDDump')
          ->search( { design_type => { -like => "%$pattern%" } },
            { prefetch => ['well'] } )->first;
        $result->design_type( defined $result->design_type
              && $result->design_type =~ m/$indel/ ? $1 : 'Cnd' );
        is $result->design_type, $expected, "design_type matches ($expected)";
    }

    sub validate_by_known_project_id {
        my ($project_id) = @_;
        my $result =
          $schema->resultset('HTGTDB::Result::EPDDump')
          ->search( { project_id => $project_id }, { prefetch => ['well'] } )
          ->first;
        $result->design_type( defined $result->design_type
              && $result->design_type =~ m/$indel/ ? $1 : 'Cnd' );
        is $result->design_type, 'Ins',
          "design_type by project_id matches (Ins)";
    }

}

SKIP: {
    skip "Skipping lengthy tests", 3
        unless $ENV{HTGTDB_RUN_LENGTHY_TESTS};

    validate_by_known_project_id(63861);

    for my $pair (
        { Del          => 'Del' },
        { Ins          => 'Ins' },
        { KO           => 'Cnd' },
        { Ins_Location => 'Ins' },
    )
        {
            validate_design_type_assignment( %{$pair} );
        }
}

done_testing();

exit 0;
