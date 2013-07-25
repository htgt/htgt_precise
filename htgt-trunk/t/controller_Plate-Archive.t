use strict;
use warnings;
use Test::Most;
use FindBin;
use HTGT::DBFactory;
use Smart::Comments;

use lib "$FindBin::Bin/lib";

BEGIN {
        $ENV{MIG_DB} = 'mig_test';
        $ENV{HTGT_CONFIG} = "$FindBin::Bin/config/preauth.yml";
        $ENV{HTGT_DB} = 'eucomm_vector_esmt';
      }
BEGIN { use_ok 'Catalyst::Test', 'HTGT'; }
BEGIN { use_ok 'HTTP::Request::Common'; }

ok( request('/plate/archive')->is_redirect, 'HTTP request returns redirect for plate/archive' );
ok( request('/plate/archive/load_archive_plate_labels')->is_success, 'Request should succeed' );

my @TEST_DATA = (
    {
        testname    => 'Nothing submitted',
        textarea    => '',
        submit      => undef,
    },
        
    {
        testname    => 'empty data',
        textarea    => '',
        response    => qr{No Data Entered},
        submit      => '1',
    },

    {
        testname    => 'Parser Error - Wrong number of values entered',
        textarea    => 'test',
        response    => qr{Missing archive label},
        submit      => '1',
    },
    
    {
        testname    => 'Parser Error 2 - badly formatted archive label',
        textarea    => 'TEST0000A,PLG84,1',
        response    => qr{Invalid archive label},
        submit      => '1',
    },
    
    {
        testname    => 'Loader Error - Archive label already exists',
        textarea    => 'TEST0000A,PG84,1',
        response    => qr{data already present archive_label = PG84},
        submit      => '1',
    },    
    
    {
        testname    => 'Good Data',       
        textarea    => 'TEST0000A,PG84,2',
        response    => qr{inserted plate_label = TEST0000A_2},
        submit      => '1',
    },
);

#Non authorised users detach to welcome page.
@HTGT::Mock::Store::USER_ROLES = qw ();
my $response = request('/plate/archive/load_archive_plate_labels');
like $response->content, qr/You are not authorised to load archive plate labels/, 'Non edit user test';
@HTGT::Mock::Store::USER_ROLES = qw ( design edit eucomm eucomm_edit );

my $schema = HTGT::DBFactory->connect('eucomm_vector');
### Connected to EUCOMM Vector
my $test_plate_array = create_test_data($schema);
### Done create test data
for my $t ( @TEST_DATA ) {
    
    my $response = request POST '/plate/archive/load_archive_plate_labels', [
        plate_data    => $t->{textarea},
        load_archives => $t->{submit}
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
                    ### Creating plate: $plate_name
                    my $plate = 
                        $schema->resultset('Plate')->create(
                            {
                            name         =>  $plate_name,
                            description  => 'Test Plate - controller_Plate-Archive.t',
                            created_user => 'controller_Plate-Archive.t'
                            }
                        );
                    if ($plate) { 
                       ### Created plate: $plate->plate_id
                        $test_plate_array{$plate_name} = $plate;
                    }
                }
                
                my $plate = $test_plate_array{'TEST0000A_1'};

                $plate->plate_data_rs->create(
                    {
                        data_type  => 'archive_label',
                        data_value => 'PG84'                    
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
