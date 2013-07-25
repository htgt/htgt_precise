use strict;
use warnings;
use Test::More;
use HTGT::DBFactory;

BEGIN { $ENV{VECTOR_QC_DB} = 'vector_qc_esmt' }
BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::QC::View' }


my $schema = HTGT::DBFactory->connect('vector_qc');
my %test_data;

ok( request('/qc/view')->is_redirect, 'HTTP request returns redirect for qc/view' );

#Insert Test Data
insert_test_data();

#Run Tests
seq_read_test();
cloneseq_test();

#Cleanup Test Data
delete_test_data();

#Testing Complete
done_testing();

#create test data hash (global variable)
sub insert_test_data {
    eval {
        #construct clone row
        $test_data{'clone_withseq'} = $schema->resultset('ConstructClone')->create({
                                      name => 'qcviewtest',  
                                      });        
        #qc_seqread row with no sequence
        $test_data{'seqread_noseq'} = $schema->resultset('QcSeqread')->create({
                                      read_name  => 'qcviewtest',
                                      sequence => undef,
                                      });
        #qc_seqread row with sequence
        $test_data{'seqread_withseq'} = $schema->resultset('QcSeqread')->create({
                                        read_name  => 'qcviewtest',
                                        sequence => 'ATCGCGTA',
                                        construct_clone_id => $test_data{'clone_withseq'}->construct_clone_id,
                                        });

    };
    
    if ($@) {
         print "Creation of test records failed: $@";
    }
}

sub delete_test_data {
    eval {
        foreach my $test_record (keys %test_data) {
            $test_data{$test_record}->delete;
        }
    };
    
    if ($@) {
         print "Deletion of test records failed: $@";
    }   
    
}

sub seq_read_test {
    
    #No seq_read id
    {
        my $res = request( '/qc/view/seq_read' );
        ok $res->is_success, 'HTTP request for seq_read succeeds';
        like ($res->content, qr/Missing or invalid seq_read id/, 'No seq_read_id.');
    }
    
    #non numeric seq_read id
    {
        my $res = request( '/qc/view/seq_read?id=123test321' );
        ok $res->is_success, 'HTTP request for seq_read succeeds';
        like ($res->content, qr/Missing or invalid seq_read id/, 'Non numeric seq_read_id.');
    }

    #Non compatible file format
    {
        my $res = request( '/qc/view/cloneseq?id='.
                  $test_data{'seqread_withseq'}->seqread_id.'&format=fastaa' );
        ok $res->is_success, 'HTTP request for seq_read id succeeds';
        like ($res->content, qr/Invalid file format/, 'Invalid file format');
    }
    
    #seq_read id not in database
    {   
        my $seqread= $schema->resultset('QcSeqread')->search_rs( {  } )->get_column('seqread_id')->max;
        my $fake_seqread_id = $seqread + 100;
        
        my $res = request( '/qc/view/seq_read?id='.$fake_seqread_id );
        ok $res->is_success, 'HTTP request for seq_read succeeds';
        like ($res->content, qr/Sequence read not found/, 'Non existant seq_read_id.');
    }
    
    #seq_read id in database but no sequence
    {        
        my $res = request( '/qc/view/seq_read?id='.$test_data{'seqread_noseq'}->seqread_id );
        ok $res->is_success, 'HTTP request for seq_read succeeds';
        like($res->content, qr/No sequence attached to seq_read/, 'Seq_read_id exists but no sequence.');
    }
    
    #seq_read id in database and has sequence - Fasta File
    {
        my $res = request( '/qc/view/seq_read?id='.$test_data{'seqread_withseq'}->seqread_id.'&format=Fasta' );
        ok $res->is_success, 'Seq_read_id sequence displayed';
        like($res->content, qr/\A\>qcviewtest\nATCGCGTA\Z/sm, 'content looks like Fasta data');
    }
    
    #seq_read id in database and has sequence - Genbank File
    {
        my $res = request( '/qc/view/seq_read?id='.$test_data{'seqread_withseq'}->seqread_id.'&format=GenBank' );
        ok $res->is_success, 'Seq_read_id sequence displayed';
        like($res->content, qr/\ALOCUS\s*qcviewtest.*atcgcgta\n\/\/\Z/sm, 'content looks like GenBank data');
    }   
    
    #seq_read id in database and has sequence - GCG File    
    {
        my $res = request( '/qc/view/seq_read?id='.$test_data{'seqread_withseq'}->seqread_id.'&format=gcg' );
        ok $res->is_success, 'Seq_read_id sequence displayed';
        like($res->content, qr/\A\nqcviewtest.*ATCGCGTA\n\Z/sm, 'content looks like GCG data');
    }
}


sub cloneseq_test {
    
    my $construct_clone_id= $schema->resultset('ConstructClone')->
                            search_rs(
                                {
                                    'qcSeqreads.construct_clone_id' => {'!=' => undef},
                                },
                                {
                                    prefetch => 'qcSeqreads'
                                }
                            )
                            ->get_column('construct_clone_id')->first;   
    
    #No construct_clone_id
    {
        my $res = request( '/qc/view/cloneseq' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like ($res->content, qr/Missing or invalid construct_clone id/, 'No construct_clone_id');
    }
    
    #Non numeric construct_clone_id
    {
        my $res = request( '/qc/view/cloneseq?id=123test321' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like ($res->content, qr/Missing or invalid construct_clone id/, 'Invalid construct_clone_id');
    }   
    
    #Non compatible file format
    {
        my $res = request( '/qc/view/cloneseq?id='.$construct_clone_id.'&format=ffasta' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like ($res->content, qr/Invalid file format/, 'Invalid file format');
    }
    
    #construct clone not found in database
    {
        my $construct_clone_id= $schema->resultset('ConstructClone')->
                                search_rs( {  } )->get_column('construct_clone_id')->max;
        my $fake_construct_clone_id = $construct_clone_id + 100;
        
        my $res = request( '/qc/view/cloneseq?id='.$fake_construct_clone_id );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like ($res->content, qr/Construct Clone not found:/, 'Non existant construct_clone_id test');
    }
    
    #no sequences data for construct clone
    {
        my $bad_construct_clone_id= $schema->resultset('ConstructClone')->
                                    search_rs(
                                        {
                                            'qcSeqreads.construct_clone_id' => undef,    
                                        },
                                        {
                                            prefetch => 'qcSeqreads'
                                        }
                                    )
                                    ->get_column('construct_clone_id')->first;        
        
        my $res = request( '/qc/view/cloneseq?id='.$bad_construct_clone_id );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like ($res->content, qr/Sequence data not found for Construct Clone/,
              'No sequence data for construct clone test');
    }
    
    #Construct clone has sequences - Fasta
    {
        my $res = request( '/qc/view/cloneseq?id='.$test_data{'clone_withseq'}->construct_clone_id.'&format=Fasta' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like($res->content, qr/\A\>qcviewtest\nATCGCGTA\Z/sm, 'content looks like Fasta data');
    }
        
    #Construct clone has sequence - Genbank File
    {
        my $res = request( '/qc/view/cloneseq?id='.$test_data{'clone_withseq'}->construct_clone_id.'&format=GenBank' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like($res->content, qr/\ALOCUS\s*qcviewtest.*atcgcgta\n\/\/\Z/sm, 'content looks like GenBank data');
    }   
    
    #Construct clone has sequence - GCG File    
    {
        my $res = request( '/qc/view/cloneseq?id='.$test_data{'clone_withseq'}->construct_clone_id.'&format=GCG' );
        ok $res->is_success, 'HTTP request for construct_clone_id succeeds';
        like($res->content, qr/\A\nqcviewtest.*ATCGCGTA\n\Z/sm, 'content looks like GCG data');
    }
    
}
