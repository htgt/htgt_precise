package MyTest::HTGT::Utils::DesignFinder::CriticalRegionError;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::Utils::DesignFinder::CriticalRegionError' );
    __PACKAGE__->mk_classdata( 'transcript' );
}

use Test::Most;
use HTGT::Utils::DesignFinder::CriticalRegionError;
use Readonly;

{
    package Bio::EnsEMBL::Transcript;

    use Moose;
    has stable_id => (
        is       => 'ro',
        isa      => 'Str',
        required => 1
    );

    no Moose;
}

sub startup :Tests(startup) {
    my $class = shift;

    $class->transcript( Bio::EnsEMBL::Transcript->new( stable_id => 'ENSMUSTMOCK001' ) );
}

sub constructor :Tests(7) {
    my $test = shift;

    can_ok $test->class, 'new';

    ok my $e = $test->class->new( type => 'NoFloxedExons' ), '...the constructor should succeed';
    isa_ok $e, $test->class, '...the object it returns';
    isa_ok $e, 'Throwable::Error', '...and it';

    ok  $test->class->new( type => 'NoFloxedExons', transcript => $test->transcript ),
        '...the constructor should succeed when passed a transcript';
    
    throws_ok { my $e = $test->class->new } qr/\QAttribute (type) is required\E/;

    throws_ok { my $e = $test->class->new( type => 'FooBarWeeWar' ) } qr/\QAttribute (type) does not pass the type constraint\E/;
}

sub throw :Tests(2) {
    my $test = shift;

    can_ok $test->class, 'throw';
    throws_ok { $test->class->throw( type => 'NoFloxedExons' ) } 'HTGT::Utils::DesignFinder::CriticalRegionError';
}

sub message :Tests(3) {
    my $test = shift;

    can_ok $test->class, 'message';

    {        
        my $e = $test->class->new( type => 'NoFloxedExons' );
        is $e->message, 'Region contains no exons';
    }

    {
        my $e = $test->class->new( type => 'NoFloxedExons', transcript => $test->transcript );
        is $e->message, "Region contains no exons (transcript ENSMUSTMOCK001)";
    }    
}



1;

__END__
