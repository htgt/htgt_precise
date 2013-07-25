#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl htgt-utils-plate-create.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl htgt-utils-plate-create.t'
#   Ray Miller <rm7@hpgen-1-14.internal.sanger.ac.uk>     2010/04/14 08:57:38

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Most;
use HTGT::DBFactory;

use strict;
use warnings FATAL => 'all';

BEGIN {
    use_ok( 'HTGT::Utils::Plate::Create' );
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';    
}

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    ok my $iterator =
      HTGT::Utils::Plate::Create::well_name_iterator( 25, 1, 'EP99999' ),
      'create 25-well iterator';
    isa_ok $iterator, 'Iterator';

    my @well_names = map $iterator->value, 1 .. 25;

    ok $iterator->is_exhausted, 'iterator is exhausted';
    is $well_names[0],  'EP99999_A01', 'first well is EP99999_A01';
    is $well_names[24], 'EP99999_E05', 'last well is EP99999_E05';

}

{

    ok my $iterator = HTGT::Utils::Plate::Create::well_name_iterator(96),
      'create 96-well iterator';
    isa_ok $iterator, 'Iterator';

    my @well_names = map $iterator->value, 1 .. 96;
    ok $iterator->is_exhausted, 'iterator is exhausted';
    is $well_names[0],  'A01', 'first well is A01';
    is $well_names[11], 'A12', 'twelfth well is A12';
    is $well_names[12], 'B01', 'thirteenth well is B01';
    is $well_names[95], 'H12', 'last well is H12';
}

{

    ok my ( $p, $w ) =
      HTGT::Utils::Plate::Create::parse_plate_well( [ 'GRD01234', 'B01' ] ),
      'parse plate,well';
    is $p, 'GRD01234', '...returns expected plate';
    is $w, 'B01',      '...returns expected well';
}

{
    ok my ( $p, $w ) =
      HTGT::Utils::Plate::Create::parse_plate_well( ['GRD01234[B01]'] ),
      'parse plate[well]';
    is $p, 'GRD01234', '...returns expected plate';
    is $w, 'B01',      '...returns expected well';
}

{
    ok my ( $p, $w ) =
      HTGT::Utils::Plate::Create::parse_plate_well( ['PG00004_A_A01_1'] ),
      'parse PG clone';
    is $p, 'PG00004_A_1', '...returns expected plate';
    is $w, 'A01',         '...returns expected well';
}

{
    ok my ( $p, $w ) =
      HTGT::Utils::Plate::Create::parse_plate_well( ['PC00001_A_A01_1'] ),
      'parse PC clone';
    is $p, 'PCS00001_A', '...returns expected plate';
    is $w, 'A01',        '...returns expected well';
}

my $htgt = HTGT::DBFactory->connect('eucomm_vector');

{
    ok my $well =
        HTGT::Utils::Plate::Create::get_well( $htgt, ['PG00004_A_A01_1'] ),
                'get_well';
    is $well->well_name, 'A01', 'well_name is A01';
    is $well->plate->name, 'PG00004_A_1', 'plate name is PG0005_A_1';
}

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_type => 'EPD',
        plate_data => [],
        created_by => 'testscript'
    );
}
    qr/plate_name not specified/;

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_name => 'foo',
        plate_data => [],
        created_by => 'testscript'
    );
}
    qr/plate_type not specified/;

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_name => 'foo',
        plate_type => 'EPD',
        created_by => 'testscript'
    );
}
    qr/plate_data not specified/;

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_name => 'foo',
        plate_type => 'EPD',
        plate_data => []
    );
}
    qr/created_by not specified/;

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_name => 'foo',
        plate_type => 'XXX',
        plate_data => [],
        created_by => 'testscript'
    );
}
    qr/Invalid plate type: XXX/;

throws_ok {
    HTGT::Utils::Plate::Create::create_plate(
        $htgt,
        plate_name => 'foo',
        plate_type => 'EPD',
        plate_data => [ [ 'EP00016[EP00016_A01]' ] ],
        created_by => 'testscript'
    );
}
    qr/Expected 96 wells for plate of type EPD, but got 1/;

test_plate_create( 'EP00016',   1 );
test_plate_create( 'EPD0023_1', 1 );
test_plate_create('GRD0001');

{
    my @args = (
        plate_name => 'GRDTEST1',
        plate_type => 'PGG',
        created_by => 'testscript',
        plate_data => [ ( ['-'] ) x 96 ]
    );

    my $plate = eval { HTGT::Utils::Plate::Create::create_plate( $htgt, @args ) };

 SKIP: 
    {
        ok defined $plate, 'create plate with empty wells' or skip 'create plate with empty wells failed', 5;
        eval {
            my @wells = $plate->wells;
            is scalar @wells, 96, 'plate has 96 wells';
            for my $w ( @wells ) {
                ok not(defined $w->design_instance_id), 'design instance id is undefined';
                ok not(defined $w->parent_well_id ), 'parent well is undefined';
            }
        };
        delete_plate( $plate );
    }
}


done_testing();

sub test_plate_create {
    my ( $template_plate_name, $well_name_inc_plate ) = @_;

    my $template =
      $htgt->resultset('Plate')->find( { name => $template_plate_name } );

    my @wells = map [ $_->plate->name, $_->well_name ], map $_->parent_well,
      $template->wells;

    ( my $plate_name = $template->name ) =~ s/0+/TEST/;
    my $plate_type = $template->type;

    my @args = (
        plate_name => $plate_name,
        plate_type => $plate_type,
        created_by => 'testscript',
        plate_data => \@wells
    );

    my $plate =
      eval { HTGT::Utils::Plate::Create::create_plate( $htgt, @args ) };
    diag( "Create plate failed: $@" ) if $@;
  SKIP: {
        ok defined $plate, "create $plate_type plate"
          or skip "$plate_type plate create failed", 6;
        eval {
            is $plate->name, $plate_name, "plate name is $plate_name";
            is $plate->type, $plate_type, "plate type is $plate_type";
            my @wells = $plate->wells;
            is scalar @wells, scalar $template->wells,
              'plate has expected number of wells';
            if ($well_name_inc_plate) {
                like $wells[0]->well_name, qr/^$plate_name/,
                  'well name begins with plate name';
            }
            else {
                unlike $wells[0]->well_name, qr/^$plate_name/,
                  'well name does not begin with plate name';
            }

        };

        throws_ok { HTGT::Utils::Plate::Create::create_plate( $htgt, @args ) }
        qr/Plate $plate_name already exists/;

        delete_plate($plate);
    }
}

sub delete_plate {
    my ($plate) = @_;

    $htgt->txn_do(
        sub {
            for my $w ( $plate->wells ) {
                $w->well_data_rs->delete;
                $w->delete;
            }
            $htgt->resultset('PlatePlate')->search(
                {
                    -or => [
                        child_plate_id  => $plate->plate_id,
                        parent_plate_id => $plate->plate_id
                    ]
                }
            )->delete;
            $plate->delete;
        }
    );
}
