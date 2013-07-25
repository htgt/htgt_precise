use strict;
use warnings;
use Test::Most;
use FindBin;
use HTGT::DBFactory;
use HTTP::Request::Common;
use HTGT::Utils::Plate::Create;
use HTGT::Utils::Plate::Delete;
use URI;
use JSON;
use Log::Log4perl ':easy';

use lib "$FindBin::Bin/lib";

BEGIN {
    $ENV{HTGT_CONFIG} = "$FindBin::Bin/config/preauth.yml";
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
    use_ok 'Catalyst::Test', 'HTGT';
    use_ok 'HTGT::Controller::Plate::Update';
}

Log::Log4perl->easy_init( $ERROR );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $parent_plate = $htgt->resultset( 'Plate' )->search( { type => 'EP' } )->first;
my $plate_name   = sprintf( 'EPDTEST_%04d', int( rand 1000 ) );
my $plate_data   = gen_plate_data( $plate_name, $parent_plate );

my %params = (
    plate_name => $plate_name,
    plate_type => 'EPD',
    plate_desc => 'TEST',
    plate_lock => '',
    plate_data => to_json( $plate_data )
);

die_on_fail;

my $res = request POST '/plate/update/_save_new_plate', Content => \%params;

ok $res->is_success, '_save_new_plate should succeed';

my $plate = $htgt->resultset( 'Plate' )->find( { name => $plate_name } );

ok $plate, 'new plate was saved to database';

is $plate->name, $plate_name, "new plate has expected name";

for my $well ( $plate->wells ) {
    my $well_name = $well->well_name;
    my $well_data = $plate_data->{ $well_name };

    is $well->parent_well->plate_id, $well_data->{parent_plate_id},
        "$well_name has expected parent_plate_id";
    
    is $well->parent_well->plate->name, $well_data->{parent_plate},
        "$well_name has expected parent_plate";

    is $well->parent_well_id, $well_data->{parent_well_id},
        "$well_name has expected parent_well_id";

    is $well->parent_well->well_name, $well_data->{parent_well},
        "$well_name has expected parent_well";

    is $well->design_instance_id, $parent_plate->wells_rs->find( { well_name => $well_data->{parent_well} } )->design_instance_id,
        "$well_name has expected design_instance_id";
}

ok HTGT::Utils::Plate::Delete::delete_plate( $plate ), "delete plate $plate_name";

done_testing();

sub gen_plate_data {
    my ( $plate_name, $parent_plate ) = @_;

    my @parent_wells = $parent_plate->wells;
    
    my $wells = HTGT::Utils::Plate::Create::well_name_iterator( 96, 1, $plate_name );

    my %plate_data;
        
    while ( $wells->isnt_exhausted ) {
        my $well_name   = $wells->value;
        my $parent_well = $parent_wells[ int rand @parent_wells ];
        $plate_data{ $well_name } = {
            parent_plate       => $parent_plate->name,
            parent_plate_id    => $parent_plate->plate_id,
            parent_well        => $parent_well->well_name,
            parent_well_id     => $parent_well->well_id
        };
    }

    return \%plate_data;    
}

__END__

