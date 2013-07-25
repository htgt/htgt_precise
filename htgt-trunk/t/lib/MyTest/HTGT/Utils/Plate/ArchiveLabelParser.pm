package MyTest::HTGT::Utils::Plate::ArchiveLabelParser;

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;

use Test::Most;
use HTGT::Utils::Plate::ArchiveLabelParser;

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Plate::ArchiveLabelParser' );
    __PACKAGE__->mk_classdata( 'o' );
    __PACKAGE__->mk_classdata( 'schema' => HTGT::DBFactory->connect('eucomm_vector' , {AutoCommit => 0}));
    __PACKAGE__->mk_classdata( 'test_data_fail' => [
            {
                testname    => 'empty data',
                textarea    => '',
                errors      => [ 'No Data Entered' ],
            },
        
            {
                testname    => 'badly formatted data, missing archive label',
                textarea    => 'test',
                errors      =>  [ 'Missing archive label' ],
            },
            
            {
                testname    => 'badly formatted data, to many values',
                textarea    => 'PG00016_A,PG84,1-2-3,1-2',
                errors      => [ 'Too many fields entered, max of 3' ],
            },
        ]    
    );
    __PACKAGE__->mk_classdata( 'test_data_pass' => [
            {
                testname    => 'Valid Input Data - default plate range',       
                textarea    => 'TEST0000A,PG84',
                data_return => [
                    {
                        plate            => 'TEST0000A_1',
                        plate_label      => 'TEST0000A_1-4',
                        archive_label    => 'PG84',
                        archive_quadrant => '1',
                    },
                    {
                        plate            => 'TEST0000A_2',
                        plate_label      => 'TEST0000A_1-4',
                        archive_label    => 'PG84',
                        archive_quadrant => '2',
                    },
                    {
                        plate            => 'TEST0000A_3',
                        plate_label      => 'TEST0000A_1-4',
                        archive_label    => 'PG84',
                        archive_quadrant => '3',                        
                    },
                    {
                        plate            => 'TEST0000A_4',
                        plate_label      => 'TEST0000A_1-4',
                        archive_label    => 'PG84',
                        archive_quadrant => '4',                        
                    }
                ],
            },
            
            {
                testname    => 'Valid Input Data',       
                textarea    => 'TEST0000A,PG85,5',
                data_return => [
                    {
                        plate            => 'TEST0000A_5',
                        plate_label      => 'TEST0000A_5',
                        archive_label    => 'PG85',
                        archive_quadrant => '1',  
                    }
                ]
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
    ok my $o = $test->class->new( schema => $test->schema ),
               'the constructor should succeed';
    isa_ok $o, $test->class, '...the object it returns';

    ok !$o->has_errors, 'fresh object has no errors';
    is $o->line_num, 0, 'line number is 0';
                
    #create test plates (5)
    my @test_plate_array;
    for (my $postfix = 1; $postfix < 6; $postfix++) {
        push @test_plate_array,
        $test->schema->resultset('Plate')->create(
            {
            name         => "TEST0000A_$postfix",
            description  => 'Test Plate - MyTest::HTGT::Utils::Plate::LoadPlateData',
            created_user => 'MyTest::HTGT::Utils::Plate::LoadPlateData'
            }
        );
    }
    $test->{test_plates} = \@test_plate_array;

    $test->o( $o );
}

sub clean_up :Tests(teardown => 3) {
    my $test = shift;

    lives_ok { $test->o->reset_line_num } 'reset_line_num';
    lives_ok { $test->o->clear_errors } 'clear_errors';
    lives_ok { $test->o->clear_seen } 'clear seen';
}

sub _quadrant :Tests(5) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, '_expand_range';
    
    is_deeply [ $o->_quadrant( 1 )], [ 1 ], 'Suffix 1 / Quadrant 1';
    is_deeply [ $o->_quadrant( 4 )], [ 4 ], 'Suffix 4 / Quadrant 4';
    is_deeply [ $o->_quadrant( 5 )], [ 1 ], 'Suffix 5 / Quadrant 1';
    is_deeply [ $o->_quadrant( 13 )], [ 1 ], 'Suffix 13 / Quadrant 1';
}

sub _expand_range :Tests(10) {
    my $test = shift;

    my $o = $test->o;
    
    can_ok $o, '_expand_range';

    is_deeply [ $o->_expand_range( 1 ) ], [ 1 ], 'range 1';
    is_deeply [ $o->_expand_range( '1-4' ) ], [1,2,3,4], 'range 1-4';
    is_deeply [ $o->_expand_range( '5-8' ) ], [5,6,7,8], 'range 1-8';

    ok !$o->_expand_range( 'squiggle' );
    is_deeply $o->errors->{0}, [ 'Invalid range (squiggle)' ], 'invalid range';

    ok! $o->_expand_range( '1-7' );
    is_deeply $o->errors->{0}, [ 'Invalid range (squiggle)',
                                 'Invalid plate number range, too many plates (1-7)'
                             ], 'range too big';
    
    ok !$o->_expand_range( '7-3' );
    is_deeply $o->errors->{0}, [ 'Invalid range (squiggle)',
                                 'Invalid plate number range, too many plates (1-7)',
                                 'Invalid plate number range, must be smaller to larger value (7-3)'
                             ], 'start > end';
}

sub _expand_plate_numbers :Tests(12) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, '_expand_plate_numbers';
    
    is_deeply [ $o->_expand_plate_numbers( '12' )], [ 12 ], 'value 12';
    is_deeply [ $o->_expand_plate_numbers( '12-15' )], [ 12,13,14,15 ], 'value 12-15';
    is_deeply [ $o->_expand_plate_numbers( '1&4' )], [ 1,4 ], 'value 1&4';
    is_deeply [ $o->_expand_plate_numbers( '1-2&4' )], [ 1,2,4 ], 'value 1-2&4';
    is_deeply [ $o->_expand_plate_numbers( '1&2&4' )], [ 1,2,4 ], 'value 1&2&4';    
    
    ok !$o->_expand_plate_numbers( 'squiggle' );
    is_deeply $o->errors->{0}, [ 'Invalid plate number range (squiggle)' ], 'invalid range (squiggle)';
    
    ok! $o->_expand_plate_numbers( '1-2-3' );
    is_deeply $o->errors->{0}, [ 'Invalid plate number range (squiggle)',
                                 'Invalid plate number range (1-2-3)'
                             ], 'invalid range (1-2-3)';    

    ok! $o->_expand_plate_numbers( '1&2-' );
    is_deeply $o->errors->{0}, [ 'Invalid plate number range (squiggle)',
                                 'Invalid plate number range (1-2-3)',
                                 'Invalid plate number range (1&2-)'
                             ], 'invalid range (1&2-)';
      
}

sub _expand_data :Tests(8) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, '_expand_data';
    
    is_deeply [ $o->_expand_data( 'PG00004_A','PG123','1' )],
              [
                {
                   plate            => 'PG00004_A_1',
                   plate_label      => 'PG00004_A_1',
                   archive_label    => 'PG123',
                   archive_quadrant => '1',
                }
              ],
              'Good Range';
              
 

    
    ok !$o->_expand_data( 'testplate','PG123','1' );
    is_deeply $o->errors->{0}, [ 'No such plate (testplate_1)' ],'invalid archive label';
    $o->clear_errors;
    
    ok !$o->_expand_data( 'PG00004_A','PG123','1' );
    is_deeply $o->errors->{0}, [ 'Duplicate Plate Entered (PG00004_A_1)' ], 'Duplicate plate';
    $o->clear_errors;
    
    $o->clear_seen;
    ok $o->_expand_data( 'PG00004_A','test','1' );
    is_deeply $o->errors->{0}, [ 'Invalid archive label (test)' ], 'invalid archive label';

}


sub _parse_line :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, '_parse_line';
    #return data array of hashes

    #failed Tests
    foreach my $t ( @{ $test->test_data_fail } ){
        ok !$o->_parse_line( $t->{textarea} );
        is_deeply $o->errors->{0}, $t->{errors},
        "$t->{testname}";
        $test->o->reset_line_num;
        $test->o->clear_errors;
    }
    
    #Pass Tests
    foreach my $t ( @{ $test->test_data_pass } ) {
        is_deeply [ $o->_parse_line( $t->{textarea} ) ], $t->{data_return},
        "$t->{testname}";
    }

}


sub parse :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    
    can_ok $o, 'parse';

    #parse calls a different subroutine and adds data to plate_data

    foreach my $t ( @{ $test->test_data_fail } ){
        ok !$o->parse( $t->{textarea} );
        my $arraynum = 1;
        $arraynum = 0 if $t->{testname} eq 'empty data';
        is_deeply $o->errors->{$arraynum}, $t->{errors},
        "$t->{testname}";
        $test->o->reset_line_num;
        $test->o->clear_errors;
    }

    #Pass Tests
    foreach my $t ( @{ $test->test_data_pass } ) {
        $o->parse( $t->{textarea} );
        is_deeply $o->plate_data, $t->{data_return},
        "$t->{testname}";
        $test->o->clear_data;
    }
}

1;