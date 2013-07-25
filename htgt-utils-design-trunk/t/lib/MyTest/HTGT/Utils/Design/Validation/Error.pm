package MyTest::HTGT::Utils::Design::Validation::Error;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

use HTGT::Utils::Design::Validation::Error;
use Test::Most;

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::Design::Validation::Error' );
}

sub constructor :Tests(4) {
    my $test = shift;

    can_ok $test->class, 'new';

    ok my $e = $test->class->new( type => 'missing_feature', mesg => 'design has no G3' ), '...the constructor should succeed';
    isa_ok $e, $test->class, '...the object it returns';

    throws_ok { $test->class->new( type => 'no_such_type', mesg => 'la la la' ) }
        qr/\QValidation failed for 'HTGT::Utils::Design::Validation::ErrorType'\E/,
            '...throws exception for invalid error type';
}

sub is_fatal :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'is_fatal';
    
    ok $test->class->new( type => 'missing_feature', mesg => '' )->is_fatal,
        'missing_feature error is fatal';

    ok !$test->class->new( type => 'constrained_element', mesg => '' )->is_fatal,
        'constrained_element error is not fatal';    
}

1;

__END__



