#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;

die_on_fail;

use_ok 'HTGT::BioMart::QueryFactory';

ok my $qf = HTGT::BioMart::QueryFactory->new( martservice => "http://www.sanger.ac.uk/htgt/biomart/martservice", timeout => 30 ),
    'Create a QueryFactory object';

ok my $q = $qf->query(
    {
        dataset => 'htgt_targ',
        filter  => {
            status => [
                "Mice - Genotype confirmed",
                "Mice - Germline transmission",
                "Mice - Microinjection in progress",
                "ES Cells - Targeting Confirmed"
            ]
        },
        attributes => [
            "marker_symbol",
            "mgi_accession_id",
            "status"
        ]
    },
    {
        dataset => "mmusculus_gene_ensembl",
        filter  => {
            "chromosome_name" => "1",
            "start"           => "1",
            "end"             => "10000000"
        },
    }
), 'Create a federated query';

my $results;

lives_and { $results = $q->results; ok @$results > 0 } 'Query should return some results';

isa_ok $results->[0], 'HASH';

done_testing;
