package HTGTDB::DesignNoteTypeDict;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_note_type_dict');
#__PACKAGE__->add_columns(qw/design_note_type_id description/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_note_type_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_101_1_design_note_type_d",
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_note_type_id/);

return 1;

