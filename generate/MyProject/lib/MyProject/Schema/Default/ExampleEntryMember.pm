package MyProject::Schema::Default::ExampleEntryMember;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_entry_members')
->add_columns(
    entry_id  => {-t => 'bigint', -u => 1},
    member_id => {-t => 'bigint', -u => 1},
    priv_cd   => {-t => 'tinyint', -u => 1, -l => '権限', -e => [
        [qw/1 admin/], [qw/2 editable/], [qw/3 viewable/],
    ]},
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/entry_id member_id/])
->add_index([qw/member_id/])
->belongs_to('entry' => 'ExampleEntry')
->belongs_to('member' => 'ExampleMember');

1;
