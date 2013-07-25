package MyTest::HTGT::Utils::Restriction::EnzymeCollection;

use strict;
use warnings;

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::Restriction::EnzymeCollection' );
}

use Test::Most;
use HTGT::Utils::Restriction::EnzymeCollection;
use Const::Fast;

const my $NUM_ENZYMES => 3754;

sub constructor :Tests(5) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $o = $test->class->new, 'constructor should succeed';
    isa_ok $o, $test->class;
    ok $o->{enzyme_collection}, '...the object has an enzyme collection';
    isa_ok $o->{enzyme_collection}, 'Bio::Restriction::EnzymeCollection', '...the enzyme collection';
}

sub instance :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'instance';
    ok my $i = $test->class->instance, 'instance should succeed';
    isa_ok $i, $test->class;
}

sub enzymes :Tests(2) {
    my $test = shift;

    can_ok $test->class->instance, 'enzymes';
    isa_ok $test->class->instance->enzymes, 'Bio::Restriction::EnzymeCollection';
}

sub each_enzyme :Tests(4) {
    my $test = shift;

    can_ok $test->class->instance, 'each_enzyme';
    ok my @enzymes = $test->class->instance->each_enzyme, 'each_enzyme should succeed';
    isa_ok $enzymes[0], 'Bio::Restriction::Enzyme', '...first element of the array';
    is @enzymes, $NUM_ENZYMES, 'expected number of enzymes in the collection';
}

sub get_enzyme :Tests(6) {
    my $test = shift;

    can_ok $test->class->instance, 'get_enzyme';
    ok my $e = $test->class->instance->get_enzyme( 'AasI' ), 'get AasI';    
    isa_ok $e, 'Bio::Restriction::Enzyme';
    is $e->name, 'AasI';
    ok $test->class->instance->get_enzyme( 'BbvCI' ), 'get BbvCI';
    ok !$test->class->instance->get_enzyme( 'ShootMeIfThereIsAnEnzymeWithThisName' ), 'non-existent enzyme';
}

sub get_enzymes :Tests(5) {
    my $test = shift;

    can_ok $test->class->instance, 'get_enzymes';
    my @enzyme_names = qw( AasI BbvCI );
    ok my $c = $test->class->instance->get_enzymes( @enzyme_names ), 'get_enzymes should succeed';
    isa_ok $c, 'Bio::Restriction::EnzymeCollection';
    my @a = $c->available_list;
    is @a, @enzyme_names, 'collection has expected number of items';
    cmp_deeply \@a, bag( @enzyme_names );    
}

sub available_list :Tests(3) {
    my $test = shift;

    can_ok $test->class->instance, 'available_list';
    ok my @available = $test->class->instance->available_list, 'available_list should succeed';
    is @available, $NUM_ENZYMES, 'expected number of enzymes in the collection';
}

sub longest_cutter :Tests(1) {
    my $test = shift;

    can_ok $test->class->instance, 'longest_cutter';
}

sub blunt_enzymes :Tests(1) {
    my $test = shift;

    can_ok $test->class->instance, 'blunt_enzymes';
}

sub cutters :Tests(1) {
    my $test = shift;

    can_ok $test->class->instance, 'cutters';
}

1;

__END__
