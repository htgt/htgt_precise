package MyTest::HTGT::Utils::Plate::LoadPlateData;

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;

use Test::Most;
use HTGT::Utils::Plate::LoadPlateData;
use HTGT::Utils::Plate::ArchiveLabelParser;

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::Plate::LoadPlateData' );
    __PACKAGE__->mk_classdata( 'o' );
    __PACKAGE__->mk_classdata( 'schema' => HTGT::DBFactory->
                              connect('eucomm_vector', {AutoCommit => 0}));
    __PACKAGE__->mk_classdata( 'test_data_pass' => [     
            {
                testname   => 'Valid Input Data',
                plate_name => 'TEST0000A_1',
                textarea => 'TEST0000A,PG84,1',
                data_input => {
                        plate_label      => 'TEST0000A_1',
                        archive_label    => 'PG84',
                        archive_quadrant => '1',  
                    }
            },             
        ] 
    );
    __PACKAGE__->mk_classdata( 'test_data_fail' => [
            {
                testname   => 'Duplicate Input Data - Different Value',
                plate_name => 'TEST0000A_2',
                textarea => 'TEST0000A,PG85,2',                
                data_input => {
                        archive_label      => 'PG85'
                    },
                create_error_log => qr{^error\sinserting\sdata},
                check_error_log  => { TEST0000A_2 => 
                    [ 'archive_label mismatch,PG85 / PG84 (new/old)' ]
                },
                load_update_log  => { TEST0000A_2 =>
                    [
                       'inserted archive_quadrant = 2',
                       'inserted plate_label = TEST0000A_2'
                    ]
                },
                check_update_log => { },
            },
            {
                testname   => 'Duplicate Input Data - Same Value',
                plate_name => 'TEST0000A_3',
                textarea => 'TEST0000A,PG84,3',                 
                data_input => {
                        archive_label      => 'PG84'
                    },
                create_error_log =>  qr{^error\sinserting\sdata},
                check_error_log  => { },
                check_update_log => { TEST0000A_3 =>
                    [ 'data already present archive_label = PG84' ]
                },
                load_update_log  => { TEST0000A_3 =>
                    [
                        'data already present archive_label = PG84',
                       'inserted archive_quadrant = 3',
                       'inserted plate_label = TEST0000A_3',
                    ]
                }
            },
        ]
    );
}

END {
    if (__PACKAGE__->schema->storage->connected) {
        __PACKAGE__->schema->txn_rollback;
    }
}

sub constructor :Tests(startup => 6) {
    my $test = shift;
    
    can_ok $test->class, 'new';
    
    my $parser = HTGT::Utils::Plate::ArchiveLabelParser->new
                ( schema => $test->schema );
    $test->{parser} = $parser;
    
    ok my $o = $test->class->new( parser => $parser, user => 'test' ),
               'the constructor should succeed';
    isa_ok $o, $test->class, '...the object it returns';

    ok !$o->has_errors, 'fresh object has no errors';
    isa_ok $o->parser, 'HTGT::Utils::Plate::PlateDataParser', 'Parser object is created';
    is $o->user, 'test', 'user is test';
    
    $test->o( $o );
}

sub clean_up :Tests(teardown => 2) {
    my $test = shift;
    
    __PACKAGE__->schema->txn_rollback;
    lives_ok { $test->o->clear_errors } 'clear_errors';
    lives_ok { $test->o->clear_log } 'clear log';
}

#setup tests - create new parser object & test data

sub pre_test :Tests(setup) {
    my $test = shift;
    
    my $schema = $test->schema;
    
    #create test plates
    my %test_plate_array;
    for (my $postfix = 1; $postfix < 4; $postfix++) {
        my $plate_name = "TEST0000A_$postfix";
        $test_plate_array{$plate_name} = 
            $test->schema->resultset('Plate')->create(
                {
                name         =>  $plate_name,
                description  => 'Test Plate - MyTest::HTGT::Utils::Plate::LoadPlateData',
                created_user => 'MyTest::HTGT::Utils::Plate::LoadPlateData'
                }
            );
    }
    $test->{test_plates} = \%test_plate_array;
    
    my $plate_2 = $test_plate_array{'TEST0000A_2'}; 
    $plate_2->plate_data_rs->create(
        {
            data_type => 'archive_label',
            data_value => 'PG84'
        }
    );
    
    my $plate_3 = $test_plate_array{'TEST0000A_3'};
    $plate_3->plate_data_rs->create(
        {
            data_type => 'archive_label',
            data_value => 'PG84'
        }
    );
    


}

#gets hashref and data_type, inserts data and creates log entry
#if errors adds to errors hash
sub _create_plate_data :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    can_ok $o, '_create_plate_data';
    
    #Pass Tests
    foreach my $t ( @{ $test->test_data_pass } ) {
        foreach my $data_type ( keys %{ $t->{data_input} } ) {
            my $update_log = "inserted $data_type = $t->{data_input}->{$data_type}";
            $o->_create_plate_data( $test->{test_plates}->{$t->{plate_name}}, $t->{data_input}, $data_type );
            is_deeply $o->update_log->{$t->{plate_name}}[0], $update_log,
                      "$t->{testname} - $data_type";
            $test->o->clear_log;
        }
    } 
}


#gets hashref and data_type, checks data and passes on to _create_plate_data
#if ok then update log is changed
#if errors adds to errors hash
#if data already exists updates log with this information
sub _check_plate_data :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    can_ok $o, '_check_plate_data';
    
    #Pass Tests
    foreach my $t ( @{ $test->test_data_pass } ) {
        foreach my $data_type ( keys %{ $t->{data_input} } ) {
            next if $data_type eq 'plate';
            my $update_log = "inserted $data_type = $t->{data_input}->{$data_type}";
            is ( $o->_check_plate_data( $test->{test_plates}->{$t->{plate_name}} ,$t->{data_input}, $data_type ),
                1,
                $t->{testname} . "- $data_type"
               );
        }
    }
    
    #Fail tests - put in data that would not work
    foreach my $t ( @{ $test->test_data_fail } ) {
        foreach my $data_type ( keys %{ $t->{data_input} } ) {
            next if $data_type eq 'plate';
            $o->_check_plate_data($test->{test_plates}->{$t->{plate_name}}, $t->{data_input}, $data_type );
            is_deeply $o->errors, $t->{check_error_log},
                      "$t->{testname} - $data_type error log";
            $test->o->clear_errors;
        }
    }    
}


#iterates though parser objects plate_data and loads data
sub load_data :Tests(no_plan) {
    my $test = shift;
    
    my $o = $test->o;
    can_ok $o, 'load_data';
    
    my $parser = $test->{parser};
    
    #Pass Tests
    foreach my $t ( @{ $test->test_data_pass } ) {
        $parser->parse( $t->{textarea} );
        $o->load_data();
        my %update_log;

        foreach my $data_type ( sort keys %{ $t->{data_input} } ) {
            push @{ $update_log{ $t->{plate_name} } },
                "inserted $data_type = $t->{data_input}->{$data_type}";
        }
        
        is_deeply $o->update_log, \%update_log,
                  "$t->{testname}";
        $test->o->clear_log;
        $parser->clear_data;
    }
    
    #Fail Tests
    foreach my $t ( @{ $test->test_data_fail } ) {
        $parser->parse( $t->{textarea} );
        $o->load_data();
        my $errors = $o->errors;
        my $log = $o->update_log;
        my $testname = $t->{testname};

        is_deeply $o->errors, $t->{check_error_log},
                  "$t->{testname} - error log";
        is_deeply $o->update_log, $t->{load_update_log},
                  "$t->{testname} - update log";                      


        $test->o->clear_errors;
        $test->o->clear_log;
        $parser->clear_data;
    }
}

1;
