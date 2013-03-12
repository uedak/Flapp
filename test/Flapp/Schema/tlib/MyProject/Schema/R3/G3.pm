package MyProject::Schema::R3::G3;
use MyProject qw/-b MyProject::Schema::R3 -s -w/;

__PACKAGE__->table('g3s');
__PACKAGE__->add_columns(
    g1_id   => {-t => 'bigint', -u => 1},
    g2_type => {-t => 'int', -u => 1},
    g3_type => {-t => 'int', -u => 1},
    name    => {-t => 'varchar', -s => 10, -l => '名前'},
);
#__PACKAGE__->table_option({engine => 'InnoDB'});
__PACKAGE__->primary_key([qw/g1_id g2_type g3_type/]);

__PACKAGE__->belongs_to(g1 => 'G1', {-l => 'G1'});
__PACKAGE__->belongs_to(g2 => 'G2',
    {-l => 'G2', -on => ['g2.g2_type = me.g2_type AND g2.g1_id = me.g1_id']});

1;
