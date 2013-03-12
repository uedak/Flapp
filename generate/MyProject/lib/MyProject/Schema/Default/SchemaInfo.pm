package MyProject::Schema::Default::SchemaInfo;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('schema_info')
->add_columns(
    version    => {-t => 'varchar', -s => 3},
    created_at => {-t => 'datetime'},
)
->primary_key([qw/version/]);

1;
