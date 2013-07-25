#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Test::Most tests => 7;

BEGIN {
    $ENV{HTGT_DB} = 'eucomm_vector_esmt';
}

die_on_fail;

ok my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' ), 'connect to eucomm_vector_esmt';

$htgt->txn_begin;

END {
    $htgt and $htgt->txn_rollback;
}

my $design = $htgt->resultset( 'Design' )->search( {} )->first;
ok $design, 'retrieve design';

ok $design->design_user_comments_rs->delete, 'delete design_user_comments';

ok !$design->is_recovery_design, 'design is not a recovery design';

my $cat = $htgt->resultset( 'DesignUserCommentCategories' )->find( { category_name => 'Recovery design' } );
ok $cat, 'retrieve recovery design category';

my $duc = $cat->design_user_comments_rs->create(
    {
        design_id   => $design->design_id,
        edited_user => $ENV{USER},
        edited_date => \'current_timestamp',
    }
);
ok $duc, 'create design_user_comment';

ok $design->is_recovery_design, 'design is a recovery design';
