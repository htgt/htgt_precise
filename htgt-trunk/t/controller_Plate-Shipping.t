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

ok( request('/plate/shipping')->is_redirect, 'HTTP request returns redirect for plate/shipping' );
ok( request('/plate/shipping/insert_plate_shipping_dates')->is_success, 'Request should succeed' );

my @TEST_DATA = (
    {
        testname    => 'Nothing submitted',
        textarea    => '',
        center      => '',
        date        => undef,           
        submit      => undef,
    },
    
    {
        testname    => 'No shipping date entered',
        textarea    => '',
        center      => 'hzm',
        date        => undef,           
        response    => qr{No shipping date was entered},
        submit      => '1',
    },

    {
        testname    => 'No plate names were entered',
        textarea    => '',
        center      => 'hzm',
        date        => 'test',           
        response    => qr{No plate names were entered},
        submit      => '1',
    },

    {
        testname    => 'Invalid shipping date entered',
        textarea    => 'TEST0000A_1',
        center      => 'hzm',
        date        => 'test',           
        response    => qr{Invalid shipping date was entered},
        submit      => '1',
    },

    {
        testname    => 'No shipping center selected',
        textarea    => 'TEST0000A_1',
        center      => undef,
        date        => 'test',        
        response    => qr{No shipping center was selected},
        submit      => '1',
    },
    
    {
        testname    => 'Invalid shipping center selected',
        textarea    => 'TEST0000A_1',
        center      => 'blah',
        date        => 'test',        
        response    => qr{No shipping center was selected},
        submit      => '1',
    },
    
    {
        testname    => 'Parser Error - Non existant plate',
        textarea    => 'test',
        center      => 'hzm',
        date        => '2010-01-01',        
        response    => qr{No such plate},
        submit      => '1',
    },
    
    {
        testname    => 'Loader Error - Ship date hzm already exists',
        textarea    => 'TEST0000A_1',
        center      => 'hzm',
        date        => '2010-01-01',        
        response    => qr{ship_date_hzm mismatch},
        submit      => '1',
    },    
    
    {
        testname    => 'Good Data',       
        textarea    => 'TEST0000A_2',
        center      => 'hzm',
        date        => '2010-01-01',
        response    => qr{inserted ship_date_hzm = 01-Jan-10},
        submit      => '1',
    },
);

#Non authorised users detach to welcome page.

@HTGT::Mock::Store::USER_ROLES = qw ();
my $response = request('/plate/shipping/insert_plate_shipping_dates');
like $response->content, qr/You are not authorised to insert plate shipping dates/, 'Non edit user test';

@HTGT::Mock::Store::USER_ROLES = qw ( design edit eucomm eucomm_edit );


my $schema = HTGT::DBFactory->connect('eucomm_vector');

my $test_plate_array = create_test_data($schema);

for my $t ( @TEST_DATA ) {
    
    my $response = request POST '/plate/shipping/insert_plate_shipping_dates', [
        shipping_plates => $t->{textarea},
        shipping_center => $t->{center},
        shipping_date   => $t->{date},
        update_shipping => $t->{submit}
    ];

    ok $response->is_success, $t->{testname}.'-HTTP request succeeds';
    like $response->content, $t->{response}, $t->{testname}.'-Response Correct'
        if ($t->{submit}); 

}

delete_test_data($test_plate_array, $schema);
done_testing();


sub create_test_data {
    my ($schema) = @_;
    my %test_plate_array;
    eval {
        $schema->txn_do (
            sub {
                for (my $postfix = 1; $postfix < 3; $postfix++) {
                    my $plate_name = "TEST0000A_$postfix";
                    
                    my $plate = 
                        $schema->resultset('Plate')->create(
                            {
                            name         =>  $plate_name,
                            description  => 'Test Plate - controller_Plate-Shipping.t',
                            created_user => 'controller_Plate-Shipping.t'
                            }
                        );
                    if ($plate) { 
                        $test_plate_array{$plate_name} = $plate;
                    }
                }
                
                my $plate = $test_plate_array{'TEST0000A_1'};

                $plate->plate_data_rs->create(
                    {
                        data_type  => 'ship_date_hzm',
                        data_value => '01-FEB-09'                    
                    }
                )
            }
        );
    };
    
    if ($@) {
        die "create_test_data failed: $@";
    }
    return \%test_plate_array;
    
}

sub delete_test_data {
    my ($test_plate_array, $schema) = @_;
    
    eval {
        $schema->txn_do (
            sub {
                foreach my $plate (values %$test_plate_array) {
                    my @plate_data = $plate->plate_data;
                    foreach my $data (@plate_data) {
                        $data->delete;
                    }
                    $plate->delete;
                }
            }
        );
    };
    
    if ($@) {
        die "delete_test_data failed: $@";
    }
    
}
