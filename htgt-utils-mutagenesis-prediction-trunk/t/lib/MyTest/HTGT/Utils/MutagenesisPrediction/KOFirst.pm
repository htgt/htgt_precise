package MyTest::HTGT::Utils::MutagenesisPrediction::KOFirst;

use strict;
use warnings FATAL => 'all';

use base qw( MyTest::HTGT::Utils::MutagenesisPrediction );

use Test::Most;
use HTGT::Utils::MutagenesisPrediction::KOFirst;
use Data::Dump 'dd';

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::MutagenesisPrediction::KOFirst' );
}

sub translation :Tests {
    my $test = shift;

    can_ok $test->class, 'translation';
    $test->test_genes(
        sub {
            ok my $p = $test->gene->translation, 'translation for ' . $test->gene_name . ' should succeed';
            isa_ok $p, 'Bio::Seq';
            is $p->alphabet, 'protein', '...the alphabet is protein';
            defined( my $protein = $test->value->{translation} ) or return;
            is $p->seq, $protein, '...it returns the expected protein';
        },
        'translation'
    );
}

sub description :Tests {
    my $test = shift;

    can_ok $test->class, 'description';
    $test->test_genes(
        sub {
            is $test->gene->description, $test->value->{ko_first_desc};
        },
        'desc',
    );
}

1;

__END__
