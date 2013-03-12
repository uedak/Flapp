package MyProject::Schema::R3::G1;
use MyProject qw/-b MyProject::Schema::R3 -s -w/;

__PACKAGE__->table('g1s');
__PACKAGE__->add_columns(
    id   => {-t => 'serial'},
    name => {-t => 'varchar', -s => 10, -l => '名前'},
);
#__PACKAGE__->table_option({engine => 'InnoDB'});
__PACKAGE__->primary_key([qw/id/]);

__PACKAGE__->has_many(g2s => 'G2', {-l => 'G2'});
__PACKAGE__->has_many(g3s => 'G3', {-l => 'G3'});

1;
