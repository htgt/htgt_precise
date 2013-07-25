package MyTest::HTGT::Utils::Plate::ShippingDateParser;

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;

use Test::Most;
use HTGT::Utils::Plate::ShippingDateParser;

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Plate::ShippingDateParser' );
    __PACKAGE__->mk_classdata( 'o' );
    __PACKAGE__->mk_classdata( 'schema' => HTGT::DBFactory->connect('eucomm_vector' , {AutoCommit => 0}));
    __PACKAGE__->mk_classdata( 'parse_line_test' => [
            {
                testname    => 'non-existant Plate',
                textarea    => 'test',
                center      => 'hzm',
                date        => '2010-12-30',
                output      => [],
                error       => [ 'No such plate (test)' ],
            },
            {
                testname    => 'Valid Data',
                textarea    => 'TEST0000A_1',
                plate_name  => 'TEST0000A_1',
                center      => 'hzm',
                date        => '2010-12-30',                
                output      => [
                                {
                                    ship_date_hzm => '30-Dec-10',
                                    plate => ''
                                }
                            ],
                error       => undef,
            },
        ]    
    );
    __PACKAGE__->mk_classdata( 'parse_test' => [
             {
                testname    => 'No Plates Entered',
                textarea    => '',
                center      => 'hzm',
                date        => '2010-12-30',                
                output      => [ ],
                error       => [ 'No Data Entered' ],
            },
             {
                testname    => 'Valid Data',
                textarea    => 'TEST0000A_2',
                plate_name  => 'TEST0000A_2',                
                center      => 'hzm',
                date        => '2009-01-01',                
                output      => [
                                {
                                    ship_date_hzm => '01-Jan-09',
                                    plate => ''
                                }
                            ],
                error       => undef,
            },                  
        ]
    );    
}

END {
    if (__PACKAGE__->schema->storage->connected) {
        __PACKAGE__->schema->txn_rollback;
    }
}

sub constructor :Tests(startup => 5) {
    my $test = shift;

    can_ok $test->class, 'new';
    ok my $o = $test->class->new( schema => $test->schema, shipping_center => 'hzm',
            ship_date => '2010-01-01' ),
               'the constructor should succeed';
    isa_ok $o, $test->class, '...the object it returns';

    ok !$o->has_errors, 'fresh object has no errors';
    is $o->line_num, 0, 'line number is 0';
                
    #create test plates (5)
    my %test_plate_array;
    for (my $postfix = 1; $postfix < 4; $postfix++) {
        my $plate_name = "TEST0000A_$postfix";
        $test_plate_array{$plate_name} = 
            $test->schema->resultset('Plate')->create(
                {
                name         =>  $plate_name,
                description  => 'Test Plate - MyTest::HTGT::Utils::Plate::ShippingDateParser',
                created_user => 'MyTest::HTGT::Utils::Plate::ShippingDateParser'
                }
            );
    }
    $test->{test_plates} = \%test_plate_array;

    $test->o( $o );
}

sub clean_up :Tests(teardown => 3) {
    my $test = shift;

    lives_ok { $test->o->reset_line_num } 'reset_line_num';
    lives_ok { $test->o->clear_errors } 'clear_errors';
    lives_ok { $test->o->clear_seen } 'clear seen';
}

sub _parse_line :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, '_parse_line';
    
    foreach my $t ( @{ $test->parse_line_test } ) {
        my $o = $test->class->new( schema => $test->schema, shipping_center => $t->{center},
           ship_date => $t->{date} );
        
        $t->{output}[0]->{plate} = $test->{test_plates}->{$t->{plate_name}}
            if $t->{plate_name};
        
        is_deeply [ $o->_parse_line($t->{textarea}) ],  $t->{output} , $t->{testname}." output";
        is_deeply $o->errors->{0}, $t->{error}, $t->{testname}." errors";
        
        $test->o->clear_errors;
        $test->o->reset_line_num;        
    }
    
}

sub parse :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, 'parse';

    foreach my $t ( @{ $test->parse_test } ) {
        my $o = $test->class->new( schema => $test->schema, shipping_center => $t->{center},
           ship_date => $t->{date} );
        
        if ($t->{plate_name}) {
            $t->{output}[0]->{plate} = $test->{test_plates}->{$t->{plate_name}};
            $o->parse($t->{textarea});
            is_deeply $o->plate_data, $t->{output} , $t->{testname}." output";
        } else {
            is_deeply [ $o->parse($t->{textarea}) ],  $t->{output} , $t->{testname}." output";
        }
        is_deeply $o->errors->{0}, $t->{error}, $t->{testname}." errors";
        
        $test->o->clear_errors;
        $test->o->clear_data;
        $test->o->reset_line_num;         
    }
    
}

1;
