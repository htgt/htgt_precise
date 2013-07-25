package MyTest::HTGT::Utils::ResetPlateParentageAndQC;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class );

use Test::Most;
use HTGT::Utils::ResetPlateParentageAndQC;

sub startup : Tests(startup => 1) {
    my $test = shift;
    use_ok 'HTGT::Utils::ResetPlateParentageAndQC';
}

sub reset_plate_parentage_and_qc : Tests(15) {
    my $test = shift;
    
    throws_ok {
        HTGT::Utils::ResetPlateParentageAndQC::reset_plate_parentage_and_qc( 'test', 'test' , $test->eucomm_vector_schema )
    } qr/Non existant parent plate \(test\)/,
    'Non existant parent plate';

    throws_ok {
        HTGT::Utils::ResetPlateParentageAndQC::reset_plate_parentage_and_qc( 'test', '33' , $test->eucomm_vector_schema )
    } qr/Could not find plate \(test\) with relevent qc results in well_data/,
    'Non existant plate';
    
    ok my $well = $test->eucomm_vector_schema->resultset('Well')->find( { well_id => '89894' } ), '..grab well';
        
    ok $well->well_data_value('clone_name'), '..well has clone name data';
    ok $well->well_data_value('distribute'), '..well has distribute data';
    ok $well->well_data_value('pass_level'), '..well has pass_level data';
    ok $well->well_data_value('qctest_result_id'), '..well has qctest_result_id';
    is $well->parent_well_id, 89765, '.. correct parent well id';
    
    ok HTGT::Utils::ResetPlateParentageAndQC::reset_plate_parentage_and_qc( 'PCS00033_A', '33' , $test->eucomm_vector_schema ), '... reset plate parentage and qc';
    
    ok my $reset_well = $test->eucomm_vector_schema->resultset('Well')->find( { well_id => '89894' } ), '..grab well';
    
    ok !$reset_well->well_data_value('clone_name'), '..no clone name data for well';
    ok !$reset_well->well_data_value('distribute'), '..no distribute data for well';
    ok !$reset_well->well_data_value('pass_level'), '..no pass_level data for well';
    ok !$reset_well->well_data_value('qctest_result_id'), '..no qctest_result_id data for well';
    is $reset_well->parent_well_id, 89768, '.. parent well id has been correctly reset';
    
}


sub validate_384_plate_for_well_parentage_reset : Tests(9) {
    my $test = shift;
    
    my @child_plate_errors;
    ok my $plate_with_child = $test->eucomm_vector_schema->resultset('Plate')->find( { name => 'PCS00033_A' } ), '..grab plate';
    ok !HTGT::Utils::ResetPlateParentageAndQC::validate_384_plate_for_well_parentage_reset( $plate_with_child, \@child_plate_errors, $test->eucomm_vector_schema ), 'validation fail';
    like $child_plate_errors[0], qr/Plate \(PCS00033_A\) already has qc and the following child plates/, '...plate has child plates';
    
    my @multi_parent_errors;
    ok my $plate_multi_parent = $test->eucomm_vector_schema->resultset('Plate')->find( { name => 'PG00222_Y_1' } ), '..grab plate';
    ok !HTGT::Utils::ResetPlateParentageAndQC::validate_384_plate_for_well_parentage_reset( $plate_multi_parent, \@multi_parent_errors, $test->eucomm_vector_schema ), 'validation fail';
    like $multi_parent_errors[0], qr/Plate \(PG00222_Y_1\) has qc and multiple parent plates, cannot reparent/, '...plate has multiple parent plates';    
    
    
    my @multi_cassette_errors;
    ok my $plate_multi_cassette = $test->eucomm_vector_schema->resultset('Plate')->find( { name => 'PG00223_Y_1' } ), '..grab plate';
    ok !HTGT::Utils::ResetPlateParentageAndQC::validate_384_plate_for_well_parentage_reset( $plate_multi_cassette, \@multi_cassette_errors, $test->eucomm_vector_schema ), 'validation fail';
    like $multi_cassette_errors[0], qr/Plate \(PG00223_Y_1\) has qc and wells have different cassettes, cannot reparent/, '...wells on plate have multiple cassettes';    

}

1;
