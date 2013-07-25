
use strict;
use warnings FATAL => 'all';

use Test::Most;
use HTGT::BioMart::QueryFactory;

use_ok 'HTGT::Utils::RegeneronGeneStatus';

SKIP: 
{   
    my $qf = HTGT::BioMart::QueryFactory->new( martservice => 'http://www.i-dcc.org/biomart/martservice' )
        or skip 5, 'failed to create query factory object';
    

    ok my $m = HTGT::Utils::RegeneronGeneStatus->new( $qf ), 'the constructor should succeed';
    isa_ok $m, 'HTGT::Utils::RegeneronGeneStatus', '...the object it returns';
    
    can_ok $m, 'status_for';
    can_ok $m, 'status_for_all';

    ok $m->status_for( 'MGI:87859' ), 'status_for should return something';
}

done_testing;
