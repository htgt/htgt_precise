package MyTest::HTGT::Utils::MutagenesisPrediction::Deletion;

use strict;
use warnings FATAL => 'all';

use base qw( MyTest::HTGT::Utils::MutagenesisPrediction );

use Test::Most;
use HTGT::Utils::MutagenesisPrediction::Deletion;
use Const::Fast;

use Data::Dump 'dd';

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::MutagenesisPrediction::Deletion' );
}

sub description :Tests {
    my $test = shift;

    can_ok $test->class, 'description';
    $test->test_genes(
        sub {
            lives_ok { print $test->gene->description . "\n" };
        }
    );

    
}

1;

__END__
