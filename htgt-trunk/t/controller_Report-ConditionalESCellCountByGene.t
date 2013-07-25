use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'HTGT' }
BEGIN { use_ok 'HTGT::Controller::Report::ConditionalESCellCountByGene' }

{
    
    my $text = "Cbx1,OTTMUSG00000001636\r\nENSMUSG00000018666\rMGI:105369 ENSMUSG00000030217";

    ok my $res = HTGT::Controller::Report::ConditionalESCellCountByGene->_parse_gene_ids( $text ), '_parse_gene_ids';
    isa_ok $res, 'HASH';

    is_deeply $res->{marker_symbol}, [ 'Cbx1' ], 'marker_symbol';
    is_deeply $res->{ensembl_gene_id}, [ 'ENSMUSG00000018666', 'ENSMUSG00000030217' ], 'ensembl_gene_id';
    is_deeply $res->{vega_gene_id}, [ 'OTTMUSG00000001636' ], 'vega_gene_id';
    is_deeply $res->{mgi_accession_id}, [ 'MGI:105369' ], 'mgi_gene_id';

    ok my ( $query, $placeholders ) 
        = HTGT::Controller::Report::ConditionalESCellCountByGene->_build_dist_es_cell_query( $res ),
            '_build_dist_es_cell_query';

    is $query, <<'EOT', 'query';
select mgi_gene.marker_symbol, mgi_gene.ensembl_gene_id, mgi_gene.mgi_accession_id, mgi_gene.vega_gene_id,
  count(distinct well.well_id) as conditional_es_cell_count
from mgi_gene
join project
  on project.mgi_gene_id = mgi_gene.mgi_gene_id
join well
  on well.design_instance_id = project.design_instance_id
join plate
  on plate.plate_id = well.plate_id
  and plate.type = 'EPD'
join well_data
  on well_data.well_id = well.well_id
  and well_data.data_type = 'distribute'
  and well_data.data_value = 'yes'
where
( mgi_gene.ensembl_gene_id in ( ?, ? )
or mgi_gene.marker_symbol in ( ? )
or mgi_gene.mgi_accession_id in ( ? )
or mgi_gene.vega_gene_id in ( ? ) )
group by mgi_gene.marker_symbol, mgi_gene.ensembl_gene_id, mgi_gene.mgi_accession_id, mgi_gene.vega_gene_id
order by mgi_gene.marker_symbol
EOT

    is_deeply $placeholders,
        ['ENSMUSG00000018666', 'ENSMUSG00000030217', 'Cbx1', 'MGI:105369', 'OTTMUSG00000001636'],
            'placeholders';
}

ok( request('/report/conditional_es_cell_count_by_gene')->is_success, 'Request should succeed' );

done_testing();
