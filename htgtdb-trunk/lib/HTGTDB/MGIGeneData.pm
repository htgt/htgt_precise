package HTGTDB::MGIGeneData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::MGIGeneData

=cut

__PACKAGE__->table("mgi_gene_data");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 marker_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_chr

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 representative_genome_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 representative_genome_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 representative_genome_build

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 entrez_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ncbi_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ncbi_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 unists_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 unists_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 unists_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_qtl_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_qtl_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_qtl_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mirbase_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mirbase_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 roopenian_sts_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 roopenian_sts_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

#__PACKAGE__->add_columns(
#  "mgi_accession_id",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "marker_type",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "marker_symbol",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "marker_name",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_chr",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "representative_genome_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "representative_genome_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "representative_genome_build",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "entrez_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ncbi_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ncbi_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ncbi_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ncbi_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "unists_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "unists_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "unists_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_qtl_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mgi_qtl_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_qtl_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mirbase_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mirbase_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "roopenian_sts_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "roopenian_sts_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "marker_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_name",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "representative_genome_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "representative_genome_chr",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "representative_genome_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "representative_genome_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "representative_genome_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "representative_genome_build",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "entrez_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ncbi_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ncbi_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ncbi_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ncbi_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "unists_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "unists_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "unists_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_qtl_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_qtl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_qtl_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mirbase_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mirbase_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "roopenian_sts_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "roopenian_sts_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key("mgi_accession_id");

=head1 RELATIONS

=head2 mgi_ensembl_gene_map

Type: might_have

Related object: L<HTGTDB::MGIEnsemblGeneMap>

=cut

__PACKAGE__->might_have(
  "mgi_ensembl_gene_map",
  "HTGTDB::MGIEnsemblGeneMap",
  { "foreign.mgi_accession_id" => "self.mgi_accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mgi_vega_gene_map

Type: might_have

Related object: L<HTGTDB::MGIVegaGeneMap>

=cut

__PACKAGE__->might_have(
  "mgi_vega_gene_map",
  "HTGTDB::MGIVegaGeneMap",
  { "foreign.mgi_accession_id" => "self.mgi_accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OEKa6/5gZJ1Y0EG5w8nnqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
