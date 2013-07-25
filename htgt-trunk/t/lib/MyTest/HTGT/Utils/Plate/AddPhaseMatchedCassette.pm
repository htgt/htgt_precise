package MyTest::HTGT::Utils::Plate::AddPhaseMatchedCassette;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Plate::AddPhaseMatchedCassette' );
}

use Test::Most;
use HTGT::Utils::Plate::AddPhaseMatchedCassette;

sub startup : Tests(startup => 2) {
    my $test = shift;
    use_ok $test->class;
    
    can_ok $test->class, 'new';
}

sub setup : Tests(setup => 2) {
    my $test = shift;
    
    my $schema = $test->eucomm_vector_schema;

    ok $test->{o} = $test->class->new(
        schema   => $schema,
        cassette => 'L1L2_GT?_LacZ_BSD',
        plate_id => 3557,
        user     => 'test',
    ), '..create test object';
    isa_ok $test->{o}, $test->class;
}

sub schema : Tests(2) {
    my $test = shift;
    
    throws_ok {
        $test->class->new(
            schema    => '',
            cassette => 'L1L2_GT?_LacZ_BSD',
            plate_id => 3557,
            user     => 'test',
        )
    } qr/Attribute \(schema\) does not pass the type constraint because: Validation failed for 'HTGTDB'/,
    'schema not specified';

    isa_ok $test->{o}->schema, 'HTGTDB', '..schema is a HTGTDB object';
}

sub cassette : Tests(3) {
    my $test = shift;
    
    throws_ok {
        $test->class->new(
            schema   => $test->eucomm_vector_schema,
            cassette => undef,
            plate_id => 3557,
            user     => 'test',
        )
    } qr/\QAttribute (phase_match_group_name) does not pass the type constraint because: Validation failed for 'Str' with value undef\E/,
    'cassette not specified';

    throws_ok {
        $test->class->new(
            schema   => $test->eucomm_vector_schema,
            cassette => 'L1L2_GTK_LacZ_BSD',
            plate_id => 3557,
            user     => 'test',
        )
    } qr/Phase match group .+ not configured/,
    'cassette does not match any phase_match_group';

    is $test->{o}->phase_match_group_name, 'L1L2_GT?_LacZ_BSD', '..cassette is correct';
}

sub plate : Tests(4) {
    my $test = shift;
    
    throws_ok {
        $test->class->new(
            schema   => $test->eucomm_vector_schema,
            cassette => 'L1L2_GT?_LacZ_BSD',
            plate_id => undef,
            user     => 'test',
        )
    }
        qr/\QAttribute (plate_id) does not pass the type constraint because: Validation failed for 'Int' with value undef\E/,
    'plate_id not specified';
    
    ok my $o = $test->class->new(
            schema   => $test->eucomm_vector_schema,
            cassette => 'L1L2_GT?_LacZ_BSD',
            plate_id => 9999999999,
            user     => 'test',
    ), '...created test object';

    throws_ok {
        $o->plate
    } qr/Failed to retrieve plate with plate_id: 9999999999/,
    'Non existent plate';

    isa_ok $test->{o}->plate, 'HTGTDB::Plate', '..plate is correct';
}

sub get_new_cassette : Tests(2) {
    my $test = shift;
    ok my $well = $test->eucomm_vector_schema->resultset('Well')->find( {well_id => '422715'}), '..grab well';        
    is $test->{o}->get_new_cassette($well), 'L1L2_GT0_LacZ_BSD', 'new phase cassette is correct'
}

sub add_phase_matched_cassette : Tests(3) {
    my $test = shift;
    
    $test->{o}->add_phase_matched_cassette;
    is_deeply $test->{o}->errors, [], 'no errors';
    ok my $well = $test->eucomm_vector_schema->resultset('Well')->find( {well_id => '422715'}), '..grab well';
    is $well->well_data_value('cassette'), 'L1L2_GT0_LacZ_BSD', 'and phase matched cassette has been added';    
}

1;
