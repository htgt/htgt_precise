use strict;
use warnings;
use Test::Most;
use FindBin;
use HTGT::DBFactory;

use lib "$FindBin::Bin/lib";

BEGIN {
        $ENV{MIG_DB} = 'mig_test';
        $ENV{HTGT_CONFIG} = "$FindBin::Bin/config/preauth.yml";
        $ENV{HTGT_DB} = 'eucomm_vector_esmt';
      }
BEGIN { use_ok 'Catalyst::Test', 'HTGT'; }
BEGIN { use_ok 'HTTP::Request::Common'; }

ok( request('/qc/update/update_qc_results')->is_success, 'Request should succeed' );

my @TEST_DATA = (
    {   testname    => 'Nothing submitted',        
        submit      => undef,
        qc_type     => 'LOA',
    },
    
    {   testname    => 'Missing QC Result',
        response    => qr{Must specify a QC Type},
        submit      => '1',
        qc_type     => '',
    },

    {   testname    => 'No data entered',         
        response    => qr{Missing or invalid upload data file},
        submit      => '1',
        qc_type     => 'LOA',
    },
);

@HTGT::Mock::Store::USER_ROLES = qw ();
ok( request('/qc/update/update_qc_results')->is_redirect, 'HTTP request returns redirect if non ' );

@HTGT::Mock::Store::USER_ROLES = qw ( design edit eucomm eucomm_edit );

for my $t ( @TEST_DATA ) {
    
    my $response = request POST '/qc/update/update_qc_results', [
        update_qc   => $t->{submit},
        qc_type     => $t->{qc_type},
        skip_header => 0,
    ];

    ok $response->is_success, $t->{testname}.'-HTTP request succeeds';
    like $response->content, $t->{response}, $t->{testname}.'-Response Correct'
        if ($t->{submit}); 

}


done_testing();