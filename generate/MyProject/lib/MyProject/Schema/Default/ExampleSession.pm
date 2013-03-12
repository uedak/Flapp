package MyProject::Schema::Default::ExampleSession;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_sessions')
->add_columns(
    id        => {-t => 'varchar', -s => 100},
    data      => {-t => 'mediumblob'},
    access_at => {-t => 'datetime'},
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/id/]);

1;
