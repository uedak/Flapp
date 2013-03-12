package MyProject::Schema::Default::ExampleCategory;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_categories')
->add_columns(
    id      => {-t => 'serial'},
    name    => {-t => 'varchar', -s => 10},
    sort_no => {-t => 'int', -u => 1}
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/id/])
->has_many(entries => 'ExampleEntry', {-on => 'category_id', -order_by => 'id'});

1;
