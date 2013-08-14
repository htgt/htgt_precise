#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use File::Temp;
use Log::Log4perl ':levels';

BEGIN {
    $ENV{HTGT_SUBMITQC_FORCE_RUN} = 'yes';
    use_ok( 'HTGT::Utils::SubmitQC' );
}

Log::Log4perl->easy_init( $DEBUG );

{    
    HTGT::Utils::SubmitQC::set_config( '/no/such/file' );
    throws_ok { HTGT::Utils::SubmitQC::get_config() } qr/No such file or directory/;
}

{
    my $conf = set_config( "XXX\nx : = y=z" );
    throws_ok { HTGT::Utils::SubmitQC::get_config() } qr/Error parsing configuration file/;        
}

{
    my $conf_str = good_config();
    my $conf = set_config( $conf_str );

    ok my $config = HTGT::Utils::SubmitQC::get_config(), 'parse good config';
    is $config->{''}{check_vector_mapping}, '/bin/echo', 'check_vector_mapping';
    is $config->{''}{output_dir}, 't/qc_runs', 'output_dir';
    is_deeply $config->{prefix_map}, { PC => 'postcre', PG => 'postgw', EPD => 'allele', BAR => 'broken' }, 'prefix_map';
    isa_ok $config->{postcre}{opt}, 'ARRAY', 'postcre opt';
    isa_ok $config->{postgw}{opt}, 'ARRAY', 'postgw opt';
    isa_ok $config->{allele}{opt}, 'ARRAY', 'allele opt';

    sleep 1; # wait a second to ensure mtime changes
    $conf_str =~ s{t/qc_runs}{/nfs/users/nfs_t/team87/qc_fun};    
    $conf->truncate(0);
    $conf->seek(0,0);
    $conf->print( $conf_str );
    $conf->flush;
    ok $config = HTGT::Utils::SubmitQC::get_config(), 'parse modified config';
    is $config->{''}{output_dir}, '/nfs/users/nfs_t/team87/qc_fun', 'modified config was re-read' 
}

{
    my $conf = set_config( good_config() );
    ok my $config = HTGT::Utils::SubmitQC::get_config(), 'parse good config';

    throws_ok { HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'PG00123', 'FOO123' ) }
        qr/prefix_map for FOO not configured/;

    throws_ok { HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'PC00123', 'BAR123' ) }
        qr/options for broken QC not correctly configured/;

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'PC00123', 'PC00123_1' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -plate PC00123_1 -tsproj PC00123 ) ],
            'check_vector_mapping for PC plate';

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'PG00123', 'PG00123_1' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -preferdi -postgate -hash /software/team87/data/qc/20091109_genomic_regions
              -cache /software/team87/data/qc/20091109_genomic_regions.store -plate PG00123_1 -tsproj PG00123 ) ],
                  'check_vector_mapping for PG plate';

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'EPD00123_B', 'EPD0123' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -preferdi -allele -plate EPD0123 -tsproj EPD00123_B -tronly ) ],
            'check_vector_mapping for EPD B plate';

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'EPD00123_Z', 'EPD0123' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -preferdi -allele -plate EPD0123 -tsproj EPD00123_Z -tponly ) ],
            'check_vector_mapping for EPD Z plate';

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'EPD00123_R', 'EPD0123' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -preferdi -allele -plate EPD0123 -tsproj EPD00123_R -fponly ) ],
            'check_vector_mapping for EPD R plate';

    is_deeply [ HTGT::Utils::SubmitQC::check_vector_mapping_cmd( $config, 'EPD00123_A', 'EPD0123' ) ],
        [ qw( /bin/echo -htgtlookup -dbstore -preferdi -allele -plate EPD0123 -tsproj EPD00123_A ) ],
            'check_vector_mapping for EPD A plate';
    
    my $outfile = HTGT::Utils::SubmitQC::outfile( $config, 'PG00123', 'out' );
    like $outfile, qr{t/qc_runs/PG00123\..+\.out$}, 'outfile';
    
    ok my @bsub = HTGT::Utils::SubmitQC::bsub_cmd( $config, 'PC00123', 'PC00123_1', 'testscript' ), 'generate bsub command';
    cmp_deeply \@bsub, [ 'bsub', '-cwd', 't/qc_runs',
                         '-o', ignore(), '-e', ignore(), qw( -u testscript -J ), ignore(), qw( -q normal -P team87 -R ),
                         'select[mem>3000] rusage[mem=3000]',
                         qw( -M 3000000 -g /team87/qc /bin/echo -htgtlookup -dbstore -plate PC00123_1 -tsproj PC00123 ) ],
                             'bsub command';
    like $bsub[4], qr{^t/qc_runs/PC00123_1\.PC00123.+\.out$}, 'outfile';
    like $bsub[6], qr{^t/qc_runs/PC00123_1\.PC00123.+\.err$}, 'errfile';
}    

{
    my $output = HTGT::Utils::SubmitQC::run_cmd( 'echo', 'hello' );
    is $output, 'hello', 'successful command returns its output';

    throws_ok { HTGT::Utils::SubmitQC::run_cmd( 'sh', '-c', 'echo boo >&2; false' ) } qr/sh failed: boo/;

    throws_ok { HTGT::Utils::SubmitQC::run_cmd( 'sh', '-c', 'echo boo >&2; false' ) } 'HTGT::Utils::SubmitQC::Exception::System';

    throws_ok { HTGT::Utils::SubmitQC::run_cmd( '/no/such/command' ) } qr{file not found: /no/such/command};

    throws_ok { HTGT::Utils::SubmitQC::run_cmd( '/no/such/command' ) } 'HTGT::Utils::SubmitQC::Exception::System';    
    
}

{
    my $conf = set_config( good_config() );
    ok my $qc_jobs = HTGT::Utils::SubmitQC::list_qc_jobs(), 'list_qc_jobs';
    cmp_deeply $qc_jobs, [
        {
            plate   => 'EPD0524_3',
            tsproj  => 'EPD00524_3_R',
            subdate => '2010-05-04 08:46:48',
            status  => 'completed'            
        },
        {
            plate   => 'EPD0529_4',
            tsproj  => 'EPD00529_4_B',
            subdate => '2010-04-28 18:54:23',
            status  => 'completed'           
        },
        {
            plate   => 'GRD90088_A',
            tsproj  => 'GRD90088_A',
            subdate => '2010-04-28 09:01:10',
            status  => 'completed'            
        },
        {
            plate   => 'GRD90088_A',
            tsproj  => 'GRD90088_A',
            subdate => '2010-04-27 16:36:23',
            status  => 'failed'
        }
    ];    
}

done_testing();

sub set_config {
    my $data = shift;

    my $tmp = File::Temp->new;
    $tmp->print( $data );
    $tmp->flush;
    
    HTGT::Utils::SubmitQC::set_config( $tmp->filename );
    
    return $tmp;    
}

sub good_config {
    <<'EOT';
check_vector_mapping = /bin/echo

output_dir = t/qc_runs

[bsub]

exec = bsub
max_parallel = 10
group = /team87/qc
queue = normal
project = team87
memory = 3000

[prefix_map]

PC  = postcre
PG = postgw
EPD = allele
BAR = broken

[postcre]

opt = -htgtlookup
opt = -dbstore

[postgw]

opt = -htgtlookup
opt = -dbstore
opt = -preferdi
opt = -postgate
opt = -hash
opt = /software/team87/data/qc/20091109_genomic_regions
opt = -cache
opt = /software/team87/data/qc/20091109_genomic_regions.store

[allele]

opt = -htgtlookup
opt = -dbstore
opt = -preferdi
opt = -allele

[broken]

opt = -broken
EOT
}



