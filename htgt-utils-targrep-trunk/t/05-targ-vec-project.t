#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

{
    package MyTest::TargVecProject;

    use Moose;
    use HTGT::DBFactory;

    has htgt_schema => (
        is         => 'ro',
        isa        => 'HTGTDB',
        lazy_build => 1
    );

    with qw( MooseX::Log::Log4perl HTGT::Utils::TargRep::TargVecProject );

    sub _build_htgt_schema {
        HTGT::DBFactory->connect('eucomm_vector', { FetchHashKeyName => 'NAME_lc' });
    }
}

use Test::Most;
use Log::Log4perl ':levels';

Log::Log4perl->easy_init( $DEBUG );

ok my $tvp = MyTest::TargVecProject->new;

lives_ok {
    my $rs = $tvp->htgt_schema->resultset( 'NewWellSummary' )->search(
        {
            pgdgr_well_id => { '!=', undef }
        },
        {
            columns  => [ 'project_id', 'pgdgr_well_id' ],
            distinct => 1
        }
    );

    my $r = $rs->next;
    $tvp->project_for_targ_vec( $r );

};


done_testing;
