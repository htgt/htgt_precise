use strict;
use warnings;

use HTGT::DBFactory;

use Test::More;
use HTGTDB;
use DateTime::Format::ISO8601;

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';    
    use_ok 'HTGTDB::RepositoryQCResult';
}

my $schema = HTGT::DBFactory->connect('eucomm_vector', { AutoCommit =>1 });

my $rep = $schema->resultset('HTGTDB::RepositoryQCResult');

sub insert  {
    if (my $r = $rep->find({ well_id => 64464})){
        $r->delete();
    }
     
    my $rec = $rep->create( {
       well_id => 64464,
       first_test_start_date => '03-JUL-07',
       latest_test_completion_date => '03-JUL-07',
       karyotype_low => 0.51,
       karyotype_high =>0.60,
       copy_number_equals_one => 'not done',
       threep_loxp_srpcr => 'pass',
       fivep_loxp_srpcr => 'pass',
       vector_integrity => 'not done'
    });
    ok $rec, '...insert data ok';
    isa_ok($rec, 'DBIx::Class::Row', '...obj returned' );
    is $rec->well_id,64464, '...the well id correct';
   
    can_ok $rec, qw(first_test_start_date latest_test_completion_date
                    karyotype_low karyotype_high copy_number_equals_one
                    threep_loxp_srpcr fivep_loxp_srpcr vector_integrity
                    );
    
    
}

sub retrieve {
    my $rep_record = $rep->find({well_id => 64464});
    ok $rep_record->first_test_start_date, '...retrieve first test start date ok';
    ok $rep_record->threep_loxp_srpcr, '...retrieve threep loxp srpcr ok';
    ok $rep_record->well->well_name, '...retrieve well name ok';
    ok $rep_record->latest_test_completion_date,'...retrieve latest_test_completion_date ok';
    ok $rep_record->karyotype_low,'...retrieve karyotype_low ok';
    ok $rep_record->karyotype_high,'...retrieve karyotype_high ok';
    ok $rep_record->copy_number_equals_one,'...retrieve copy_number_equals_one ok';
    ok $rep_record->threep_loxp_srpcr,'...retrieve threep_loxp_srpcr ok';
    ok $rep_record->fivep_loxp_srpcr,'...retrieve fivep_loxp_srpcr ok';
    ok $rep_record->vector_integrity,'...retrieve vector_integrity ok';
    can_ok $rep_record, qw(well_id first_test_start_date latest_test_completion_date
                    karyotype_low karyotype_high copy_number_equals_one
                    threep_loxp_srpcr fivep_loxp_srpcr vector_integrity
                    );
}

sub update {
   my $updated_rec = $rep->find({well_id => 64464})->update({
         latest_test_completion_date => '03-NOV-09'
         });
   
    is $updated_rec->latest_test_completion_date, DateTime::Format::ISO8601->parse_datetime('2009-11-03'),'... update ok';
}

sub dele {
    $rep->search({well_id => 64464})->first()->delete();
    
}

insert();

retrieve();

update();

dele();

done_testing();
