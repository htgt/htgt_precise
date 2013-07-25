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

ok( request('/design/primers/short_range_loxp_primers')->is_success, 'Request should succeed' );

my @TEST_DATA = (
    {
        testname    => 'Nothing submitted',
        textarea    => '',          
        submit      => undef,
    },

    {
        testname    => 'No data entered',
        textarea    => '',          
        response    => qr{No Data Entered},
        submit      => '1',
    },

    {
        testname    => 'Invalid epd well name entered',
        textarea    => 'EPD99999999999',        
        response    => qr{EPD well does not exist: EPD99999999999},
        submit      => '1',
    },

    {
        testname    => 'Invalid gene marker symbol',
        textarea    => 'test',        
        response    => qr{Marker Symbol / EPD well does not exist: test},
        submit      => '1',
    },
);

my @TEST_DATA_UPDATE = (
    {
        testname => 'Nothing submitted - update',
        input => '',
        epd_well_primer => '',
        result   => '',
        primer   => '' ,
        submit   => undef,
    },
    
    {
        testname => 'No EPD Well primers - update',
        input    => '',
        epd_well_primer => '',
        result   => '',
        primer   => '' ,
        submit   => 1,
        response => qr{No epd well primers to update},
    },
    
    {
        testname => 'Invalid EPD well - update',
        input    => 'EPD99999999999',
        epd_well_primer => 'EPD99999999999-LR1',
        result   => 'pass',
        submit   => 1,
        response => qr{Well does not exist: EPD99999999999},
    },
    
    {
        testname => 'No update value for epd well primer - update',
        input    => 'EPD99999999999',
        epd_well_primer => 'EPD99999999999-LR1',
        result   => '',
        submit   => 1,
        response => qr{Cannot find update value for EPD99999999999-LR1},
    },
    
    {
        testname => 'Non existant epd well - update',
        input    => 'EPD99999999999',
        epd_well_primer => 'EPD99999999999-LR1',
        result   => 'pass',
        submit   => 1,
        response => qr{Well does not exist: EPD99999999999},
    },

);

@HTGT::Mock::Store::USER_ROLES = qw ();
my $response = request('/design/primers/short_range_loxp_primers');
like $response->content, qr/You are not authorised to view this page/, 'Non edit user test';

@HTGT::Mock::Store::USER_ROLES = qw ( design edit eucomm eucomm_edit );

for my $t ( @TEST_DATA ) {
    
    my $response = request POST '/design/primers/short_range_loxp_primers', [
        input_data  => $t->{textarea},
        get_primers => $t->{submit}
    ];

    ok $response->is_success, $t->{testname}.'-HTTP request succeeds';
    like $response->content, $t->{response}, $t->{testname}.'-Response Correct'
        if ($t->{submit}); 

}

for my $t ( @TEST_DATA_UPDATE ) {
    
    my $response = request POST '/design/primers/short_range_loxp_primers', [
        original_input_data => $t->{input},
        update_used_primers => $t->{submit},
        epd_well_primer     => $t->{epd_well_primer},
        'primer_result_'. $t->{epd_well_primer} => $t->{result},
    ];

    ok $response->is_success, $t->{testname}.'-HTTP request succeeds';
    like $response->content, $t->{response}, $t->{testname}.'-Response Correct'
        if ($t->{submit}); 

}

done_testing();
