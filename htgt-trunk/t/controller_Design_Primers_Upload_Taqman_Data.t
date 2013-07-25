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

ok( request('/design/primers/upload_taqman_assay_data')->is_success, 'Request should succeed' );

my @TEST_DATA = (
    {   testname    => 'Nothing submitted',        
        submit      => undef,
    },
    
    {   testname    => 'Missing Plate Name',
        response    => qr{You must specify a plate name},
        submit      => '1',
    },

    {   testname    => 'No data file uploaded',         
        plate_name  => 'Test_Plate',
        response    => qr{Missing or invalid upload data file},
        submit      => '1',
    },
);

@HTGT::Mock::Store::USER_ROLES = qw ();
my $response = request('/design/primers/upload_taqman_assay_data');
like $response->content, qr/You are not authorised to view this page/, 'Non edit user test';

@HTGT::Mock::Store::USER_ROLES = qw ( design edit eucomm eucomm_edit );


for my $t ( @TEST_DATA ) {

    my $response = request POST '/design/primers/upload_taqman_assay_data',
        [
        upload_taqman_data => $t->{submit},
        plate_name         => $t->{plate_name},
        ];

    ok $response->is_success, $t->{testname}.'-HTTP request succeeds';
    like $response->content, $t->{response}, $t->{testname}.'-Response Correct'
        if ($t->{submit}); 

}


done_testing();
