use strict;
use warnings;
use Test::More;
use URI;
use FindBin;
use HTGT::DBFactory;

use lib "$FindBin::Bin/lib";

BEGIN {
    $ENV{HTGT_CONFIG} = "$FindBin::Bin/config/preauth.yml";
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
    use_ok 'Catalyst::Test', 'HTGT';
    use_ok 'HTGT::Controller::Gene::Update';
}    

my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

{
    my $res = request( '/gene/update/duplicate_project' );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/Create duplicate project failed: project_id not specified/, 'error - project_id not specified';    
}

{
    my ( $project_id ) = $dbh->selectrow_array( 'select max(project_id) from project' );
    $project_id += 100;        
    
    my $res = request( "/gene/update/duplicate_project?project_id=$project_id" );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/Create duplicate project failed: project $project_id not found/, 'error - project_id not found';
}

{
    my ( $project_id ) = $dbh->selectrow_array( <<'EOT' );
select project_id from project p1
where design_id is not null
and exists (
  select project_id 
  from project p2 
  where p1.mgi_gene_id = p2.mgi_gene_id 
  and p2.design_id is null
)
EOT

    my $res = request( "/gene/update/duplicate_project?project_id=$project_id" );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/Create duplicate project failed: there is a project available to assign design/, 'error - project available';
}

{
    my ( $project_id ) = $dbh->selectrow_array( <<'EOT' );
select project_id from project p1
where design_id is not null
and not exists (
  select project_id 
  from project p2 
  where p1.mgi_gene_id = p2.mgi_gene_id 
  and p2.design_id is null
)
EOT

    my $res = request( "/gene/update/duplicate_project?project_id=$project_id" );
    ok $res->is_redirect, "HTTP request returns redirect";
    my $uri = URI->new( $res->header( 'location' ) );
    is $uri->path, '/report/gene_report', 'redirect to /report/gene_report';
    like $uri->query, qr/project_id=\d+/, 'project_id specified in redirect';    
}

#Testing update_project_publicly_reported
{
    my $res = request( '/gene/update/update_project_publicly_reported' );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/error: project_id not specified/,
    'update_project_publicly_reported: error - project_id not specified';    
}

{
    my ( $project_id ) = $dbh->selectrow_array( 'select max(project_id) from project' );
    $project_id += 100;        
    
    my $res = request( "/gene/update/update_project_publicly_reported?project_id=$project_id" );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/error: project_id not found/,
    'update_project_publicly_reported: error - project_id not found';
}

{
    my ( $project_id ) = $dbh->selectrow_array( 'select max(project_id) from project' );
    
    my $res = request( "/gene/update/update_project_publicly_reported?project_id=$project_id" );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/error: publicly reported value empty/,
    'update_project_publicly_reported: error - publicly reported value empty';
}

{
    my ( $project_id ) = $dbh->selectrow_array( 'select max(project_id) from project' );
    
    my $res = request( "/gene/update/update_project_publicly_reported?project_id=$project_id"
                      . '&name=xyz' );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/error: publicly reported value invalid/,
    'update_project_publicly_reported: error - publicly reported value invalid';
}

{
    my ( $project_id ) = $dbh->selectrow_array( 'select max(project_id) from project' );
    my ( $is_publicly_reported )
        = $dbh->selectrow_array( 'select max(description) from project_publicly_reported_dict');
    
    my $res = request( "/gene/update/update_project_publicly_reported?project_id=$project_id"
                      . '&name=' . $is_publicly_reported );
    ok $res->is_success, 'HTTP request succeeds';
    like $res->content, qr/$is_publicly_reported/,
    'update_project_publicly_reported: error - publicly reported value invalid';
}
    
done_testing();
