package MyTest::HTGT::BioMart::Query;

use base qw( Test::Class Class::Data::Inheritable );
use Test::Most;

BEGIN {
    __PACKAGE__->mk_classdata( class => 'HTGT::BioMart::Query' );
    __PACKAGE__->mk_classdata( 'query_factory' );
    __PACKAGE__->mk_classdata( 'query_obj' );
}

sub startup : Tests( startup => 4 ) {
    my $test = shift;
    
    require_ok $test->class;
    can_ok $test->class, 'new';  
    
    use_ok 'HTGT::BioMart::QueryFactory';
    ok $test->query_factory( HTGT::BioMart::QueryFactory->new( { martservice =>'http://www.i-dcc.org/biomart/martservice' } ) ), '...query factory instantiated';
}

sub setup : Tests( setup => 2 ) {
    my $test = shift;
    
    ok my $query = $test->query_factory->query( { dataset => "dcc" } ), '...the factory query succeeds';
    isa_ok $query, 'HTGT::BioMart::Query', '...the object it returns';
    
    $test->query_obj( $query );
}

sub ua : Tests(2) {
    my $test = shift;
    
    can_ok $test->query_obj, 'ua';
    isa_ok $test->query_obj->ua, 'LWP::UserAgent', '...the object it returns'; 
}

sub martservice : Tests(3) {
    my $test = shift;
    
    can_ok $test->query_obj, 'martservice';
    isa_ok $test->query_obj->martservice, 'URI', '...the object it returns';
    is $test->query_obj->martservice, $test->query_factory->martservice,
        '...it has the same URI as the factory';
}

# sub dataset : Tests(2) {
#     my $test = shift;
    
#     can_ok $test->query_obj, 'dataset';
#     is $test->query_obj->dataset, "dcc";
# }

sub schema : Tests(2) {
    my $test = shift;
    
    can_ok $test->query_obj, 'schema';
    is $test->query_obj->schema, 'default', '...default value is correct';
}

# sub filter : Tests(4) {
#     my $test = shift;
    
#     my $q = $test->query_obj;
#     can_ok $q, 'filter';
#     $q->filter( { foo => 1 } );
#     is_deeply $q->filter, { foo => 1 }, '...we can set filter to a HASH';
#     throws_ok { $q->filter( ['die', 'sucker'] ) }
#          qr/Validation failed/,  '...we cannot set it to an ARRAY';
#     throws_ok { $q->filter( 'die, sucker' ) }
#          qr/Validation failed/, '...we cannot set it to a string';        
# }

# sub available_attributes : Tests(3) {
#     my $test = shift;
    
#     my $q = $test->query_obj;
#     can_ok $q, 'available_attributes';
#     isa_ok $q->available_attributes, 'ARRAY';
#     ok grep { $_ eq 'secondary_mgi_accession_id' } @{ $q->available_attributes },
#         '...secondary_mgi_accession_id is available';
# }

# sub default_attributes : Tests(4) {
#     my $test = shift;
    
#     my $q = $test->query_obj;
#     can_ok $q, 'default_attributes';
#     isa_ok $q->default_attributes, 'ARRAY';
#     ok grep { $_ eq 'mgi_accession_id' } @{ $q->available_attributes },
#         '...mgi_accession_id is a default';
#     ok grep { $_ eq 'secondary_mgi_accession_id' } @{ $q->available_attributes },
#         '...secondary_mgi_accession_id is not a default';    
# }

# sub attributes : Tests(3) {
#     my $test = shift;
    
#     my $q = $test->query_obj;
    
#     can_ok $q, 'attributes';
#     isa_ok $q->attributes, 'ARRAY';
#     $q->attributes( [ 'foo', 'bar', 'baz' ] );
#     is_deeply( $q->attributes, [ 'foo', 'bar', 'baz' ] ), '...we can set attributes to an array ref';
# }

sub dataset_config_version : Tests(2) {
    my $test = shift;
    
    my $q = $test->query_obj;
    can_ok $q, 'dataset_config_version';
    is $q->dataset_config_version, '0.6', '...dataset config version is 0.6';
}

sub to_xml : Tests(2) {
    my $test = shift;
    
    my $q = $test->query_obj;
    
    can_ok $q, 'to_xml';
    $q->dataset(0)->filter( { marker_symbol => ['art4', 'cbx1'] } );
    ok my $xml = $q->to_xml, '...to_xml succeeds when a filter is given';
    
    my $expected = <<'EOT';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE Query>
<Query virtualSchemaName="default" datasetConfigVersion="0.6" uniqueRows="1"><Dataset name="dcc" interface="default"><Attribute name="status" /><Attribute name="mouse_available" /><Attribute name="ikmc_project_id" /><Attribute name="marker_symbol" /><Attribute name="vector_available" /><Attribute name="mgi_accession_id" /><Attribute name="ikmc_project" /><Attribute name="escell_available" /><Filter name="marker_symbol" value="art4,cbx1" /></Dataset></Query>
EOT
    # is $xml, $expected, '...generated XML is as expected';     
}

sub results : Tests(6) {
    my $test = shift;
$DB::single=1;    
    my $q = $test->query_obj;
    
    can_ok $q, 'results';
    $q->dataset(0)->filter( { marker_symbol => ['art4', 'cbx1'], project => 'KOMP-Regeneron' } );
    ok my $results = $q->results, '...we can call results()';
    isa_ok $results, 'ARRAY', '...the value it returns';
#    is scalar( @$results ), 1, '...the test search returns 1 result';
    # No - it returns 2 results
    is scalar( @$results ), 2, '...the test search returns 2 results';
    isa_ok $results->[0], 'HASH', '...the first result';
    
    $q->dataset(0)->attributes( ['bogusbogusbogusbogus'] );
    throws_ok { $q->results } qr/BioMart::Exception/, '...bogus attribute triggers error';
}

1;

__END__
