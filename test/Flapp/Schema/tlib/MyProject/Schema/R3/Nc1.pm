package MyProject::Schema::R3::Nc1;
use MyProject qw/-b MyProject::Schema::R3 -s -w/;

__PACKAGE__->table('nc1s');
__PACKAGE__->add_columns(
    id => {-t => 'serial'},
);
__PACKAGE__->table_option({engine => 'InnoDB'});
__PACKAGE__->primary_key([qw/id/]);

__PACKAGE__->has_many(nc2s => 'Nc2', {-no_cache => 1});

1;
