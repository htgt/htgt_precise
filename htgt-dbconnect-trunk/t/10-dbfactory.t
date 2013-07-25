
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-dbconnect/trunk/t/01-dbconnect.t $
# $LastChangedDate: 2009-10-02 16:49:37 +0100 (Fri, 02 Oct 2009) $
# $LastChangedRevision: 83 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Test::Most tests => 19;

use_ok 'HTGT::DBFactory';

my $config = test_config();

ok( HTGT::DBFactory::DBConnect->ConfigFile( $config->filename ), 'configured HTGT::DBFactory::DBConnect' );

can_ok 'HTGT::DBFactory', 'connect';
can_ok 'HTGT::DBFactory', 'dbi_connect';
can_ok 'HTGT::DBFactory', 'params';

delete $ENV{HTGT_DB}; 
throws_ok { HTGT::DBFactory->connect( 'eucomm_vector' ) }
    qr/Environment variable HTGT_DB not set/,
    'throws exception when env var not set';

{
    $ENV{HTGT_DB} = 'eucomm_vector_devel';
    my @params = HTGT::DBFactory->params( 'eucomm_vector' );
    is $params[0], 'dbi:Oracle:esmt', 'dsn is dbi:Oracle:esmt';
    is $params[1], 'eucomm_vector', 'username is eucomm_vector';
    is $params[2], 'eucomm_vector', 'password is eucomm_vector';
}

{
    $ENV{HTGT_DB} = 'eucomm_vector';
    my @params = HTGT::DBFactory->params( 'eucomm_vector' );
    is $params[0], 'dbi:Oracle:migp_ha', 'dsn is dbi:Oracle:migp_ha';
}

{
    $ENV{HTGT_DB} = 'eucomm_vector';
    my $params = HTGT::DBFactory->params_hash( 'eucomm_vector' );
    is_deeply( $params, {
        dsn => 'dbi:Oracle:migp_ha',
        user => 'eucomm_vector',
        password => 'eucomm_vector',
        AutoCommit  => 1,
        RaiseError  => 1,
        PrintError  => 0,
        LongReadLen => 2097152,
        on_connect_do => [ 'alter session set NLS_SORT=BINARY_CI',
                            'alter session set NLS_COMP=LINGUISTIC' ] 
    }, '...returns expected hash' );
}

{
    $ENV{HTGT_DB} = 'eucomm_vector_no_defaults';
    my $params = HTGT::DBFactory->params_hash( 'eucomm_vector' );
    is_deeply( $params, {
        dsn => 'dbi:Oracle:esmt',
        user => 'eucomm_vector',
        password => 'eucomm_vector',
        AutoCommit  => 1,
        RaiseError  => 1,
        PrintError  => 0,
    }, '...returns expected hash' );
}


SKIP: {
    eval "require HTGTDB";
    skip 'Cannot load HTGTDB model', 3
        if $@;
    $ENV{HTGT_DB} = 'eucomm_vector_test';
    ok my $schema = HTGT::DBFactory->connect( 'eucomm_vector' ), 'connect succeeds';
    isa_ok $schema, 'DBIx::Class::Schema';
    is dbname( $schema->storage->dbh ), 'ESMT.WORLD', '...connected to ESMT.WORLD';
};

{
    $ENV{HTGT_DB} = 'eucomm_vector_test';
    ok my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' ), 'dbi_connect succeeds';
    is dbname( $dbh ),  'ESMT.WORLD', '...connected to ESMT.WORLD';
}

{
    # Fall through to database not known to DBFactory
    ok my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector_devel' ), 'dbi_connect succeesds';
    is dbname( $dbh ),  'ESMT.WORLD', '...connected to ESMT.WORLD';
}

sub dbname {
    my $dbh = shift;
    my ( $dbname ) = $dbh->selectrow_array( <<'EOT' );
select property_value db_name from database_properties where property_name='GLOBAL_DB_NAME'
EOT
    return $dbname;
}

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
    model = HTGTDB
    dsn = dbi:Oracle:esmt
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database eucomm_vector_devel>
    model = HTGTDB
    dsn = dbi:Oracle:esmt
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database eucomm_vector>
    model = HTGTDB
    dsn = dbi:Oracle:migp_ha
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database eucomm_vector_no_model>
    dsn = dbi:Oracle:migd
    user = eucomm_vector
    password = eucomm_vector
</Database>

<Database eucomm_vector_no_defaults>
    dsn = dbi:Oracle:esmt
    user = eucomm_vector
    password = eucomm_vector
    no_default_attrs = 1
    <Attributes>
        AutoCommit = 1
        RaiseError = 1
        PrintError = 0
    </Attributes>
</Database>
EOT
    $tmp->close;
    return $tmp;
}
