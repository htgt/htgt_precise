package MyTest::HTGT::BioMart::QueryFactory;

use base qw( Test::Class Class::Data::Inheritable );
use Test::Most;

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::BioMart::QueryFactory' );
    __PACKAGE__->mk_classdata( 'obj' );
}

sub startup : Tests( startup => 1 ) {
    my $test = shift;
    use_ok $test->class;
}

sub constructor : Tests( setup => 3 ) {
    my $test = shift;
    my $class = $test->class;
    
    can_ok $class, 'new';
    ok my $obj = $class->new( { martservice => 'http://www.i-dcc.org/biomart/martservice' } ), '...the constructor succeeds';
    isa_ok $obj, $class, '...the object it returns';
    $test->obj( $obj );
}

sub martservice : Tests(2) {
    my $test = shift;
    
    can_ok $test->obj, 'martservice';
    isa_ok $test->obj->martservice, 'URI';
}

sub proxy : Tests(2) {
    my $test = shift;
    
    can_ok $test->obj, 'proxy';
    isa_ok $test->obj->proxy, 'URI';
}

sub timeout : Tests(2) {
    my $test = shift;
    
    can_ok $test->obj, 'timeout';
    is $test->obj->timeout, 10, '...the default timeout is 10';
}

sub ua : Tests(2) {
    my $test = shift;
    
    can_ok $test->obj, 'ua';
    isa_ok $test->obj->ua, 'LWP::UserAgent';
}

sub datasets : Tests(3) {
    my $test = shift;
    
    can_ok $test->obj, 'datasets';
    my $ds = $test->obj->datasets;
    isa_ok $ds, 'ARRAY', '...the reference it returns';
    ok grep( $_ eq 'dcc', @{ $ds } ), '...the list contains "dcc"';
}

sub validate_dataset : Tests(4) {
    my $test = shift;
    
    can_ok $test->obj, 'validate_dataset';
    throws_ok { $test->obj->validate_dataset() }
        qr/Query dataset not specified/,
        '...validation of null dataset fails';
    throws_ok { $test->obj->validate_dataset( 'boondoggle' ) }
        qr/Dataset '.*' not recognized by this factory/,
        '..."boondogle" is not a valid dataset';
    is $test->obj->validate_dataset( "dcc" ), "dcc",
        '..."dcc" is a valid dataset';
       
}

sub query : Tests(no_plan) {
    my $test = shift;
    
    can_ok $test->obj, 'query';
    ok my $query = $test->obj->query( { dataset => "dcc" } ), '...the call succeeds';
    isa_ok $query, 'HTGT::BioMart::Query', '...the object it returns';
}  

1;

__END__
