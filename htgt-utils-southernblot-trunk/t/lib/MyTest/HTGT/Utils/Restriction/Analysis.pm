package MyTest::HTGT::Utils::Restriction::Analysis;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Restriction::Analysis' );
    __PACKAGE__->mk_classdata( 'enzyme_names' => [ qw(SanDI BstPI BspEI AccI) ] );
    __PACKAGE__->mk_classdata( 'seq' );
    __PACKAGE__->mk_classdata( 'enzymes' );
    __PACKAGE__->mk_classdata( 'o' );
}

use HTGT::Utils::Restriction::Analysis;
use Test::Most;
use Bio::SeqIO;
use Bio::Restriction::EnzymeCollection;
use FindBin;

sub make_fixture :Test(startup) {
    my $class = shift;

    my $seq_io = Bio::SeqIO->new(
        -file   => "$FindBin::Bin/data/221342.gbk",
        -format => 'genbank'
    );
    $class->seq( $seq_io->next_seq );


    my $complete_collection = Bio::Restriction::EnzymeCollection->new();
    my $my_collection  = Bio::Restriction::EnzymeCollection->new( -empty => 1 );
    $my_collection->enzymes( map $complete_collection->get_enzyme( $_ ), @{ $class->enzyme_names } );
    $class->enzymes( $my_collection );

    $class->o( $class->class->new( seq => $class->seq, enzymes => $class->enzymes ) );
}

sub constructor :Tests(6) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $ra = $test->class->new( $test->seq ), 'single-argument constructor';
    isa_ok $ra, $test->class, '...the object it returns';

    ok $test->class->new( seq => $test->seq ), 'two argument constructor';

    ok $test->class->new( seq => $test->seq, enzymes => $test->enzymes ), 'three argument constructor';

    throws_ok { $test->class->new( enzymes => $test->enzymes ) } qr/\QAttribute (seq) is required\E/, 'seq not specified';
}

sub _seq :Tests(2) {
    my $test = shift;

    can_ok $test->o, 'seq';
    is $test->o->seq->seq, $test->seq->seq, 'expected sequence';
}

sub _enzymes :Tests(6) {
    my $test = shift;

    can_ok $test->o, 'enzymes';
    isa_ok $test->o->enzymes, 'Bio::Restriction::EnzymeCollection';
    ok $test->o->enzymes->get_enzyme( $_ ) for @{ $test->enzyme_names };
}

sub delegated_methods :Tests(11) {
    my $test = shift;

    for my $method ( qw( cut multiple_digest positions fragments fragment_maps sizes
                         cuts_by_enzyme cutters unique_cutters zero_cutters max_cuts ) ) {
        can_ok $test->o, $method;        
    }
}

1;

__END__
