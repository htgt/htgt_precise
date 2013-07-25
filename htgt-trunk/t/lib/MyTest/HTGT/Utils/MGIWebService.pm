package MyTest::HTGT::Utils::MGIWebService;

use strict;
use warnings FATAL => 'all';
use HTGT::DBFactory;
use Net::Ping;

use Test::Most;
use HTGT::Utils::MGIWebService;

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Utils::MGIWebService' );
    __PACKAGE__->mk_classdata('o');
    __PACKAGE__->mk_classdata( 'schema' =>
            HTGT::DBFactory->connect( 'eucomm_vector', { AutoCommit => 0 } )
    );
    __PACKAGE__->mk_classdata(
        'test_data' => [
            {   testname   => 'Valid MGI ID',
                get_mgi_only => '0',
                gene_id    => 'MGI:3840148',
                attributes => [ 'ensembl', 'vega' ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl => 'ENSMUSG00000089862',
                        vega    => 'OTTMUSG00000029336'
                    }
                ]
            },
            {   testname   => 'Valid MGI ID, blank attributes',
                get_mgi_only => '1',
                gene_id    => 'MGI:3840148',
                attributes => [ ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl => 'ENSMUSG00000089862',
                        vega    => 'OTTMUSG00000029336'
                    }
                ]
            },            
            {   testname   => 'Valid MGI ID, nomenclature request',
                gene_id    => 'MGI:3840148',
                get_mgi_only => '0',
                attributes => [ 'ensembl', 'vega', 'nomenclature' ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl  => 'ENSMUSG00000089862',
                        vega     => 'OTTMUSG00000029336',
                        nomenclature => {
                                featureType => 'protein coding gene',
                                name        => 'predicted gene 16039',
                                symbol      => 'Gm16039'
                            }
                    }
                ]
            },
            {   testname   => 'Valid MGI ID, location request',
                get_mgi_only => '0',
                gene_id    => 'MGI:3840148',
                attributes => [ 'ensembl', 'vega', 'location' ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl  => 'ENSMUSG00000089862',
                        vega     => 'OTTMUSG00000029336',
                        location => {
                                chr => '6',
                                end => '   8547480',
                                start => '   8209288',
                                strand => '+',
                            }
                    }
                ]
            },
            {   testname   => 'Valid MGI ID, request mgi id',
                get_mgi_only => '1',
                gene_id    => 'MGI:3840148',
                attributes => [ 'ensembl', 'vega', 'mgi' ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl => 'ENSMUSG00000089862',
                        vega    => 'OTTMUSG00000029336',
                        mgi     => 'MGI:3840148',
                    }
                ]
            },
            {   testname   => 'Valid Ensembl ID, request mgi and vega',
                get_mgi_only => '1',
                gene_id    => 'ENSMUSG00000089862',
                attributes => [ 'vega', 'mgi' ],
                pass       => '1',
                gene_data  => [
                    {
                        vega    => 'OTTMUSG00000029336',
                        mgi     => 'MGI:3840148',
                    }
                ]
            },
            {   testname   => 'Valid Ensembl ID, request just mgi id',
                get_mgi_only => '1',
                gene_id    => 'ENSMUSG00000089862',
                attributes => [ 'mgi' ],
                pass       => '',

            },    
            {
                testname => 'Valid MGI ID 2',
                get_mgi_only => '0',
                gene_id  => 'MGI:1919502',
                attributes => [ 'ensembl', 'vega' ],
                pass       => '1',
                gene_data  => [
                    {
                        ensembl => 'ENSMUSG00000038165'
                    }
                ]
            },           
            {   testname   => 'Blank MGI ID',
                get_mgi_only => '0',
                gene_id    => '',
                attributes => [ 'ensembl', 'vega' ],
                pass       => '',
            },

            {   testname   => 'Invalid MGI',
                get_mgi_only => '0',
                gene_id    => 'MGI:123123123123123',
                attributes => [ 'ensembl', 'vega' ],
                pass       => '1',
                gene_data  => [ {} ]
            },
            {   testname   => 'Invalid Attributes',
                get_mgi_only => '0',
                gene_id    => 'MGI:3840148',
                attributes => ['test'],
                pass       => '',
                gene_data  => []
            },
        ]
    );
}

#
#SKIP TEST IF WE CANT REACH WEB SERVICE
#

sub SKIP_CLASS {
    my $test = shift;
    
    my $o = $test->class->new();
            
    if  ($o->get_mgi_gene_info('MGI:3840148')) {
        return;
    }
    else {
        return 'Could not reach MGI web service';       
    }
}

sub constructor : Tests(startup => 6) {
    my $test = shift;

    can_ok $test->class, 'new';

    ok my $o = $test->class->new(), 'the constructor should succeed';
    isa_ok $o, $test->class, '...the object it returns';

    is $o->proxy, 'http://services.informatics.jax.org/mgiws',
        'default proxy set';
    is $o->timeout, 10, 'default timeout set';
    is $o->email, 'htgt@sanger.ac.uk', 'default email set';

    $test->o($o);
}

sub _create_request : Tests(no_plan) {
    my ($test) = shift;

    my $o = $test->o;
    can_ok $o, '_create_request';

    foreach my $t ( @{ $test->test_data } ) {
        next if $t->{get_mgi_only};
        ok $o->_create_request( $t->{gene_id}, $t->{attributes} ),
            '_create_request: ' . $t->{testname};
    }

}

sub _dispatch_request : Tests(no_plan) {
    my ($test) = shift;

    my $o = $test->o;
    can_ok $o, '_create_request';

    foreach my $t ( @{ $test->test_data } ) {
        next if $t->{get_mgi_only};
        my ( $request, $soap )
            = $o->_create_request( $t->{gene_id}, $t->{attributes} );
        if ( $t->{pass} ) {
            is_deeply $o->_dispatch_request( $request, $soap, $t->{attributes} ),
                $t->{gene_data},
                '_dispatch_request: '. $t->{testname};
        }
        else {
            ok !$o->_dispatch_request( $request, $soap ),
                '_dispatch_request: ' . $t->{testname};
        }
    }
    my ( $request, $soap )
        = $o->_create_request( 'MGI:3840148', [ 'ensembl', 'vega' ] );
    ok !$o->_dispatch_request( '', $soap ), 'Invalid Request Object';
}

sub get_mgi_gene_info : Tests(no_plan) {
    my ($test) = @_;

    my $o = $test->o;
    can_ok $o, 'get_mgi_gene_info';

    foreach my $t ( @{ $test->test_data } ) {
        if ( $t->{pass} ) {
            ok $o->get_mgi_gene_info( $t->{gene_id}, @{ $t->{attributes} } ),
                'get_mgi_gene_info' . $t->{testname};
            is_deeply $o->get_mgi_gene_info( $t->{gene_id}, @{ $t->{attributes} } ),
                $t->{gene_data},
                'get_mgi_gene_info: ' . $t->{testname};
        }
        else {
            ok !$o->get_mgi_gene_info( $t->{gene_id}, $t->{attributes} ),
                'get_mgi_gene_info' . $t->{testname};
        }
    }

    my %input_test = (
        proxy => 'test',
        timeout => '-1',
    );
    
    foreach my $type (keys %input_test) {
        ok my $o = $test->class->new( $type => $input_test{$type} ),
            'Constructor passed';
        is $o->$type, $input_test{$type}, "$type set correctly";
        
        ok !$o->get_mgi_gene_info( 'MGI:3840148', [ 'ensembl', 'vega' ] ),
            "bad $type test";
    }
}

1;
