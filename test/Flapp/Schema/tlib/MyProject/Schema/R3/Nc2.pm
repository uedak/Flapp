package MyProject::Schema::R3::Nc2;
use MyProject qw/-b MyProject::Schema::R3 -s -w/;

__PACKAGE__->table('nc2s');
__PACKAGE__->add_columns(
    id      => {-t => 'serial'},
    nc1_id  => {-t => 'bigint', -u => 1},
);
__PACKAGE__->table_option({engine => 'InnoDB'});
__PACKAGE__->primary_key([qw/id/]);

__PACKAGE__->belongs_to(nc1 => 'Nc1');

1;
