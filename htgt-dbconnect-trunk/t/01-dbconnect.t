#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-dbconnect/trunk/t/01-dbconnect.t $
# $LastChangedDate: 2011-04-15 16:36:25 +0100 (Fri, 15 Apr 2011) $
# $LastChangedRevision: 4767 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;

use_ok( 'HTGT::DBFactory::DBConnect' );

my $config = test_config();

ok( HTGT::DBFactory::DBConnect->ConfigFile( $config->filename ) );

my @params = HTGT::DBFactory::DBConnect->params( 'eucomm_vector_test' );
is( $params[0], 'dbi:Oracle:esmt', 'dsn' );
is( $params[1], 'eucomm_vector', 'user' );
is( $params[2], 'eucomm_vector', 'password' );

is_deeply( $params[3], { AutoCommit => 1, 
                         RaiseError => 1,
                         PrintError => 0,
                         LongReadLen => 2097152,
                         on_connect_do => [ 'alter session set NLS_SORT=BINARY_CI',
                                            'alter session set NLS_COMP=LINGUISTIC',
                                          ]
                        }, 'connect attrs' );

is( (HTGT::DBFactory::DBConnect->params( 'vector_qc'))[3]->{LongReadLen}, 144000, 
     'override DefaultAttributes' );

is( (HTGT::DBFactory::DBConnect->params( 'eucomm_vector_test', { AutoCommit => 0 } ) )[3]->{AutoCommit}, 0,
    'override Attributes' );

ok( HTGT::DBFactory::DBConnect->dbi_connect( 'eucomm_vector_test' ), 'dbi_connect' );

ok( HTGT::DBFactory::DBConnect->dbi_connect_cached( 'eucomm_vector_test' ), 'dbi_connnect_cached' );

sub test_config {
    require File::Temp;
    my $tmp = File::Temp->new();
    $tmp->print(<<'EOT');
<DefaultAttributes>
	AutoCommit  = 1
    RaiseError  = 1
    PrintError  = 0
    LongReadLen = 2097152
    on_connect_do = alter session set NLS_SORT=BINARY_CI
    on_connect_do = alter session set NLS_COMP=LINGUISTIC
</DefaultAttributes>

<Database eucomm_vector_test>
    dsn = dbi:Oracle:esmt
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database eucomm_vector>
    dsn = dbi:Oracle:esmp
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database vector_qc>
    dsn = dbi:Oracle:utlp_ha
    user = vector_qc
    password = VS50GIZN
    <Attributes>
        LongReadLen = 144000
    </Attributes>
</Database>

<Database vector_qc_test>
    dsn = dbi:Oracle:utlt
    user = vector_qc
    password = vector_qc
    <Attributes>
        LongReadLen = 144000
    </Attributes>
</Database>

<Database kermits>
   dsn = dbi:Oracle:utlp_ha
   user = external_mi
   password = re1ndeer
   <Attributes>
      LongReadLen = 144000
   </Attributes>
</Database>
EOT
    $tmp->close;
    return $tmp;
}




