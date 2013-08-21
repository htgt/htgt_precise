package MyTest::HTGT::Utils::TaqMan::Design::Sequence;

use strict;
use warnings FATAL => 'all';

use base qw( HTGT::Test::Class Class::Data::Inheritable );

#Fixture data project ids
#34614 - KO design
#22733 - del design
#43350 - fail disp feat

#test file creation for split sponsor option?

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
        sequence   => 1,
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
    ok does_role($test->{o}, 'HTGT::Utils::TaqMan::Design::Sequence'),
        '..consumes HTGT::Utils::TaqMan::Design::Sequence role';
}

sub fetch_wildtype_critical_data : Tests(2) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $data{chromosome} = $test->{KO}{design}->info->chr_name;
    $test->{o}->fetch_wildtype_critical_data(\%data, $test->{KO}{features});

    my $expected_data = {
        '3_flank' => 'TTTAACAGAACCCATGAACTGGGTCTTGTTTTCTTTCTCTCTCTGTCGCTAAACTAGAGGTAATTAGGGGAAGCCCAGGACTGTAGCTGCTAAGAGCTTCCTGTAGGTGCATCTTTAATCTCTGCTGGGCCACAGCACAGGCAGGAACCTC',
        '5_flank' => 'TAATTCTCCTTAGACACTTGTTAAGAAGAGGCCCTGCTTTGGAAAGGCCTCTAGGTCCTGAGGGAAGGAAAGGCCAATCGCAGAGAGATTTTCCTGGGGGTAGGGCTTAGGTTGCTGGCAGATGGAGGGTGCCTTTCACTGTGTCCGTTCT',
    };

    is $data{'3_flank'}, $expected_data->{'3_flank'},'.. 3_flank sequence is correct';
    is $data{'5_flank'}, $expected_data->{'5_flank'},'.. 5_flank sequence is correct';
}

sub fetch_wildtype_deleted_data : Tests(1) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $data{chromosome} = $test->{KO}{design}->info->chr_name;
    $test->{o}->fetch_wildtype_deleted_data(\%data, $test->{KO}{features});

    my $expected_data = {
        d_3_flank => 'ATGGCAGCTGGGCTGGAGAAGCGGGTAGTGACTGGAAACTTATTCCCACACTGAGTCTGCTGAGAAAGCATGGTCAGATCAGAAATAGACAAGATTTTTAGAATGCCAAGTTCACTCTTACCCTTTGCTCCCGAATGAGAAAAAACGTTCC',
        d_5_flank => 'TCTCAATCAGCGAGGCTGGCTTTGGGCTTTTGTGGGACCGTCCTGACTTTCTCAGGCCTGGCTCTCTGGATCATCACTCCTAATTAGATAGCAGAGTGGCTTTTAACAGAACCCATGAACTGGGTCTTGTTTTCTTTCTCTCTCTGTCGCT',
        d_deleted => 'AAACTAGAGGTAATTAGGGGAAGCCCAGGACTGTAGCTGCTAAGAGCTTCCTGTAGGTGCATCTTTAATCTCTGCTGGGCCACAGCACAGGCAGGAACCTCCTACTCCTGCTGGTGTGACTTGGGGG',
        u_3_flank => 'AGGGCTTAGGTTGCTGGCAGATGGAGGGTGCCTTTCACTGTGTCCGTTCTTTTTTTTAATATGTGGATTTATCACCTTAAACTAAAGTAGAGTCCTCAATAGATGCTTAGCAGCATGTGGTCAGCATGGATCTGTGAGGCCATCCCGAAGC',
        u_5_flank => 'ATAAAATAATGACTCAAGGGTCAGGGTGTAAAAGCTGGTGATAGAGCTGCCAAAATAATATAGAGCAAATTCTAATTCTCCTTAGACACTTGTTAAGAAGAGGCCCTGCTTTGGAAAGGCCTCTAGGTCCTGAGGGAAGGAAAGGCCAATC',
        u_deleted => 'GCAGAGAGATTTTCCTGGGGGT',
        chromosome => '2',
        strand => -1,
    };

    is_deeply(\%data, $expected_data, '..expected sequence data returned');
}

sub fetch_wildtype_data_non_KO_design : Tests(2) {
    my $test = shift;
    my %data;
    $data{strand} = $test->{strand};
    $data{chromosome} = $test->{KO}{design}->info->chr_name;
    $test->{o}->fetch_wildtype_data_non_KO_design(\%data, $test->{del}{features});

    my $expected_data = {
        '3_flank' => 'TTCTGGAAAGATAATGTGTGAATTTGGTTTTGTCATGGAATACTTTGGTTTCTCCATCTATGGTAATTGAGAGTTTGTCTGGGTATAGTAACCTGGGCTGGTGTTTGTGTTCTCTTAGGGTCTGTATAACATCTGTCCAGGATCTTCTGGC',
        '5_flank' => 'AGGGGATAACCATAGGGGCCCTTGGATTAGTACCCAATAAAATACTCAAATTGATCCAGGTGGCAGCACTTTCCTAACTAACCACCCCAATGTTGTGGTTTCCTGATGAAAGACACACAGCTTTTATATTTTAATATGCCTAAAAGAGTCT',
    };

    is $data{'3_flank'}, $expected_data->{'3_flank'},'.. 3_flank sequence is correct';
    is $data{'5_flank'}, $expected_data->{'5_flank'},'.. 5_flank sequence is correct';
}

1;
