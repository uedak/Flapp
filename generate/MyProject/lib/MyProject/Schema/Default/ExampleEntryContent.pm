package MyProject::Schema::Default::ExampleEntryContent;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_entry_contents')
->add_columns(
    entry_id => {-t => 'bigint', -u => 1},
    text     => {-t => 'mediumtext', -l => 'テキスト'},
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/entry_id/])
->belongs_to(entry => 'ExampleEntry');

1;
