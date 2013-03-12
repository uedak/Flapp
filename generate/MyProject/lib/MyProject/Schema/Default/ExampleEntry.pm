package MyProject::Schema::Default::ExampleEntry;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_entries')
->add_columns(
    id           => {-t => 'serial'},
    category_id  => {-t => 'bigint', -u => 1, -n => 1, -l => 'カテゴリ'},
    created_at   => {-t => 'datetime'},
    updated_at   => {-t => 'timestamp'},
    lock_version => {-t => 'tinyint', -u => 1, -d => 1},
    title        => {-t => 'varchar', -s => 10, -l => 'タイトル'},
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/id/])
->belongs_to(category => 'ExampleCategory')
->might_have(content => 'ExampleEntryContent', {-on => 'entry_id', -l => 'コンテンツ'})
->has_many(entry_members => 'ExampleEntryMember',
    {-on => 'entry_id', -order_by => 'member_id', -l => 'メンバー'})
->many_to_many(members => 'entry_members' => 'member');

sub validate {
    my $self = shift;
    $self->SUPER::validate(@_);
    $self->errors->add(entry_members => 111) if !@{$self->entry_members};
    $self;
}

1;
