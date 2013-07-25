package MyTest::HTGT::Utils::TaqMan::Design::Coordinates;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

#Fixture data project ids
#34614 - KO design
#22733 - del design
#43350 - fail disp feat

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::TaqMan::Design' );
}

use Test::Most;
use Moose::Util qw( does_role );
use HTGT::Utils::TaqMan::Design;

sub startup : Tests(startup => 8) {
    my $test = shift;
    use_ok $test->class;

    my $test_file = IO::File->new_tmpfile or die('Could not create temp test file ' . $!);
    $test_file->print('test' . "\n");
    $test_file->seek(0,0);
    $test->{file} = $test_file;

    my $schema = $test->eucomm_vector_schema;
    ok $test->{o} = $test->class->new(
        schema     => $schema,
        target     => 'critical',
        sequence   => 0,
        input_file => $test_file,
        ),
        '..create test object';
    ok $test->{KO}{design} = $schema->resultset('Design')->find( { design_id => 41044 } ),
        '..get KO design';
    ok $test->{del}{design} = $schema->resultset('Design')->find( { design_id => 233442 } ),
        '.. get deletion design';
    ok $test->{fail}{design} = $schema->resultset('Design')->find( { design_id => 220202 } ),
        '.. get invalid design';
    ok $test->{KO}{features} = $test->{KO}{design}->validated_display_features,
        '.. get KO design display features';
    ok $test->{del}{features} = $test->{del}{design}->validated_display_features,
        '.. get deleteion design display features';
    ok $test->{fail}{features} = $test->{fail}{design}->validated_display_features,
        '.. get invalid design display features';

    $test->{strand} = -1;    #for both designs
}

sub constructor :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'new';
    isa_ok $test->{o}, $test->class, '..constructor returned correct object';
    ok does_role($test->{o}, 'HTGT::Utils::TaqMan::Design::Coordinates'), '..consumes HTGT::Utils::TaqMan::Design::Coordinates role';
}

sub target : Tests(2) {
    my $test = shift;

    throws_ok {
        $test->class->new(
            schema     => $test->eucomm_vector_schema,
            target     => 'test',
            input_file => $test->{file},
        )
    } qr/Invalid target: test, must be either 'critical' or 'deleted'/,
    '..target not valid';
    is $test->{o}->target, 'critical', '..target is correct';
}

sub target_region_code : Tests(2) {
    my $test = shift;

    is_deeply $test->{o}->target_region_code, [ 'c' ], '.. deleted region code is c';

    my $t = $test->class->new(
        schema     => $test->eucomm_vector_schema,
        target     => 'deleted',
        input_file => $test->{file},
    );

    is_deeply $t->target_region_code, [ 'd', 'u' ], '.. deleted region code is array with d and u';
}

sub fetch_wildtype_critical_data : Tests(2) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $test->{o}->fetch_wildtype_critical_data(\%data, $test->{KO}{features});

    is $data{critical_start}, 172937633, '..critical region start coordinates are correct';
    is $data{critical_end}, 172938243, '..critical region end coordinates are correct';
}

sub fetch_wildtype_deleted_data : Tests(4) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $test->{o}->fetch_wildtype_deleted_data(\%data, $test->{KO}{features});

    is $data{u_deleted_start}, 172938294, '..deleted U region start coordinates are correct';
    is $data{u_deleted_end}, 172938315, '..deleted U region end coordinates are correct';
    is $data{d_deleted_start}, 172937456, '..deleted D region start coordinates are correct';
    is $data{d_deleted_end}, 172937582, '..deleted D region end coordinates are correct';
}

sub fetch_wildtype_data_non_KO_design : Tests(2) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $test->{o}->fetch_wildtype_data_non_KO_design(\%data, $test->{del}{features});

    is $data{critical_start}, 95963928, '..critical region start coordinates for non KO design are correct';
    is $data{critical_end}, 95968953, '..critical region end coordinates for non KO design are correct';
}

sub assert_required_features_present : Tests(3) {
    my $test = shift;

    ok $test->{o}->assert_required_features_present($test->{del}{features}, 'del');
    ok $test->{o}->assert_required_features_present($test->{KO}{features}, 'KO');
    throws_ok {$test->{o}->assert_required_features_present( $test->{fail}{features}, 'Del' )}
        qr/missing required feature/, '..design does not have required display features';
}

sub get_marker : Tests(1) {
    my $test = shift;

    is $test->{o}->get_marker($test->{del}{design}, 'del'), 'Calcoco2', '..correct marker symbol for design';
}

sub get_strand : Tests(1) {
    my $test = shift;

    is $test->{o}->get_strand($test->{del}{features}, 'del'), -1, '..correct strand for design';
}

sub get_chromosome : Tests(1) {
    my $test = shift;

    is $test->{o}->get_chromosome($test->{del}{features}, 'del'), 11, '..correct chromosome for design';
}

sub get_design_by_id : Tests(3) {
    my $test = shift;

    ok my $design = $test->{o}->get_design_by_id('41044'), '..can grab design';
    isa_ok $design, 'HTGTDB::Design';

    throws_ok { $test->{o}->get_design_by_id('1') }
        qr/failed to retrieve design 1/, '..can not retrieve non existant design'

}

sub fetch_data_for_design : Tests(4) {
    my $test = shift;

    ok my $data = $test->{o}->fetch_data_for_design($test->{del}{design}), '..can grab design data';

    is $data->{design_type}, 'Del_Block', '..design type is correct';
    is $data->{design_id}, 233442, '..design id is correct';
    is $data->{sponsor}, 'KOMP', '.. sponors are correct';
}

sub get_taqman_target_data : Tests(2) {
    my $test = shift;

    my $t = $test->class->new(
        schema     => $test->eucomm_vector_schema,
        target     => 'deleted',
        input_file => $test->{file},
    );

    throws_ok { $t->get_taqman_target_data( 'test' ) } qr/failed to retrieve design test/,  '..  returns false when invalid design specified';
    ok $t->get_taqman_target_data( 233442 ), '.. returns true when valid design given';

}

sub coordinates_plus : Tests(2) {
    my $test = shift;

    my $design_features = $test->{KO}{features};

    ok my $coordinates = $test->{o}->coordinates_plus( 'U5', 'U3', $design_features );
    is_deeply $coordinates, { start => '172938365', end => '-' }, '.. coordinates are correct';
}

sub coordinates_minus : Tests(2) {
    my $test = shift;

    my $design_features = $test->{KO}{features};

    ok my $coordinates = $test->{o}->coordinates_minus( 'U5', 'U3', $design_features );
    is_deeply $coordinates, { start => '172938294', end => '172938315' }, '.. coordinates are correct';
}

1;
