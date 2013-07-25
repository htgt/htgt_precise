use strict;
use warnings FATAL => 'all';
use Test::Most;
use HTGT::DBFactory;

BEGIN {
    use_ok('HTGT::Utils::AlterParentWell');
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
    $ENV{VECTOR_QC_DB} = 'vector_qc_esmt';
    $ENV{KERMITS_DB} = 'kermits_esmt';
}

my $schema = HTGT::DBFactory->connect('eucomm_vector');

$schema->txn_do(
   sub {
        test_plate_type();
	test_same_parent();
	test_no_child_well();
	test_update_cases();
        $schema->txn_rollback;
    }
);

done_testing();

sub test_plate_type {
    my $plate = $schema->resultset('HTGTDB::Plate')->search( { type =>'DESIGN'} )->first;
    my $well = $plate->wells->first;

    my $parent_plate = $schema->resultset('HTGTDB::Plate')->search( { type => 'EP'} )->first;
    my $parent_well = $parent_plate->wells->first;
    
    throws_ok { HTGT::Utils::AlterParentWell::alter_parent_well($well,$parent_well,$ENV{USER}) } qr/reparenting of this well not allowed/, 'not allow to reparent design plate';
    
    my $well_2 = $schema->resultset('HTGTDB::Plate')->search( { type => 'PGD' } )->first->wells->first;
    my $parent_well_2 = $schema->resultset('HTGTDB::Plate')->search(
	{ type => 'PCS' }
    )->first->wells->first;
    
    throws_ok { HTGT::Utils::AlterParentWell::alter_parent_well($well_2, $parent_well_2,$ENV{USER})} qr/reparenting of this well not allowed/, 'not allow to reparent PG plate ';
}

sub test_same_parent {
    my $ws = $schema->resultset('HTGTDB::WellSummaryByDI')->search({
        'EP_WELL_ID' => { '!=' , undef }
    })->first;
    
    my $well_id = $ws->ep_well_id;
    my $well = $schema->resultset('HTGTDB::Well')->find({ well_id => $well_id });

    my $count = HTGT::Utils::AlterParentWell::alter_parent_well($well, $well->parent_well, $ENV{USER});
    is $count, 0, '...return 0 for assigning same parent';
}

sub test_no_child_well {
    my $ws = $schema->resultset('HTGTDB::WellSummaryByDI')->search({
	'PGDGR_WELL_ID' => { '!=', undef },
	'EP_WELL_ID' => { '!=', undef },
	'EPD_WELL_ID' => undef
        })->first;
    
    my $well =  $schema->resultset('HTGTDB::Well')->find($ws->ep_well_id);
  
    my $ws_2 = $schema->resultset('HTGTDB::WellSummaryByDI')->search({
	'PGDGR_WELL_ID' => { '!=', $well->parent_well_id }
    })->first;
    
    my $parent_well = $schema->resultset('HTGTDB::Well')->find($ws_2->pgdgr_well_id);
    
    my $count = HTGT::Utils::AlterParentWell::alter_parent_well($well, $parent_well, $ENV{USER});
    is $count, 1, '...return 1 for no child well'; 
}

sub test_update_cases {    
    my $ws = $schema->resultset('HTGTDB::WellSummaryByDI')->search({
	'PGDGR_WELL_ID' => { '!=', undef },
	'EP_WELL_ID' => { '!=', undef },
	'EPD_WELL_ID' => { '!=', undef } 
    })->first;
  
    my $well = $schema->resultset('HTGTDB::Well')->find($ws->ep_well_id);
    
    my $ws_2 = $schema->resultset('HTGTDB::WellSummaryByDI')->search( {
	'PGDGR_WELL_ID' => { '!=', $well->parent_well_id },
	'DESIGN_INSTANCE_ID' => { '!=', $well->design_instance_id }
    })->first;
    
    my $parent_well =  $schema->resultset('HTGTDB::Well')->find($ws_2->pgdgr_well_id);
    
    my $count_of_child_wells = find_child_wells($well->well_id);
    my $expected_count_of_updated_wells = $count_of_child_wells + 1 ;
    
    is HTGT::Utils::AlterParentWell::alter_parent_well($well, $parent_well, $ENV{USER}) , $expected_count_of_updated_wells, 'return '. $expected_count_of_updated_wells ;
}

sub find_child_wells {
    my ($well_id) = @_;
   
    my $count = 0;
    my @child_wells = $schema->resultset('HTGTDB::Well')->search(
	{ parent_well_id => $well_id }
    );
    
    $count += scalar(@child_wells);
  
    foreach my $w (@child_wells){
	$count += find_child_wells($w->well_id);
    }
    return $count;
}
