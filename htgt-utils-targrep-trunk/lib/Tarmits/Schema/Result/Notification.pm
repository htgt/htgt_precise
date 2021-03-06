use utf8;
package Tarmits::Schema::Result::Notification;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Notification

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<notifications>

=cut

__PACKAGE__->table("notifications");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'notifications_id_seq'

=head2 welcome_email_sent

  data_type: 'timestamp'
  is_nullable: 1

=head2 welcome_email_text

  data_type: 'text'
  is_nullable: 1

=head2 last_email_sent

  data_type: 'timestamp'
  is_nullable: 1

=head2 last_email_text

  data_type: 'text'
  is_nullable: 1

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "notifications_id_seq",
  },
  "welcome_email_sent",
  { data_type => "timestamp", is_nullable => 1 },
  "welcome_email_text",
  { data_type => "text", is_nullable => 1 },
  "last_email_sent",
  { data_type => "timestamp", is_nullable => 1 },
  "last_email_text",
  { data_type => "text", is_nullable => 1 },
  "gene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 contact

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Tarmits::Schema::Result::Contact",
  { id => "contact_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 gene

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Tarmits::Schema::Result::Gene",
  { id => "gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TkVIVehqaFwLIl9ccRGIzQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
