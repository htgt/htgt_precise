package MyTest::HTGT::Utils::DesignFinder::Transcript;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

use Test::Most;
use HTGT::Utils::DesignFinder::Transcript;
use Bio::EnsEMBL::Registry;

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::DesignFinder::Transcript' );

    __PACKAGE__->mk_classdata( t1 => 'ENSMUST00000000001' ); # good
    __PACKAGE__->mk_classdata( t2 => 'ENSMUST00000132989' ); # not protein coding
    __PACKAGE__->mk_classdata( t4 => 'ENSMUST00000073196' ); # invalid intron length and invalid splicing
    __PACKAGE__->mk_classdata( t5 => 'ENSMUST00000155078' ); # NMD
}

sub constructor :Tests(4) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $t = $test->class->new( $test->t1 ), 'constructor succeeds';
    isa_ok $t, $test->class, '...the object it returns';
    is $t->stable_id, $test->t1, '...it has the expected EnsEMBL transcript';
}

sub is_valid_coding_transcript :Tests(6) {
    my $test = shift;

    can_ok $test->class, 'is_valid_coding_transcript';

    ok $test->class->new( $test->t1 )->is_valid_coding_transcript, 't1 is a valid conding transcript';
    for my $t ( qw( t2 t4 t5 ) ) {
        ok !$test->class->new( $test->$t )->is_valid_coding_transcript, "$t is not a valid coding transcript";
    }
}

sub has_valid_intron_length :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'has_valid_intron_length';
    ok $test->class->new( $test->t1 )->has_valid_intron_length, 't1 has valid intron length';
    ok !$test->class->new( $test->t4 )->has_valid_intron_length, 't4 has invalid intron length';
}

sub has_valid_splicing :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'has_valid_splicing';
    ok $test->class->new( $test->t1 )->has_valid_splicing, 't1 has valid splicing';
    ok !$test->class->new( $test->t4 )->has_valid_splicing, 't3 has invalid splicing';
}

sub is_nmd :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'is_nmd';
    ok !$test->class->new( $test->t1 )->is_nmd, 't1 is not subject to NMD';
    ok $test->class->new( $test->t5 )->is_nmd, 't5 is subject to NMD';
}

sub stable_id :Tests(2) {
    my $test = shift;

    can_ok $test->class, 'stable_id';
    is $test->class->new( $test->t1 )->stable_id, $test->t1, 'id returns transcript stable_id';
}

sub stringify :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'stringify';
    my $t = $test->class->new( $test->t1 );
    is $t->stringify, $test->t1, 'stringify returns transcript stable_id';
    is "$t", $test->t1, 'overloading ""';
}

sub check_complete :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'check_complete';

    throws_ok { $test->class->new( $test->t1 )->is_complete } qr/\Qmust call check_complete() before is_complete()\E/;

    my $t1 = $test->class->new( $test->t1 );

    ok $t1->check_complete( $t1 ), 'check_complete should succeed';
}


1;

__END__
