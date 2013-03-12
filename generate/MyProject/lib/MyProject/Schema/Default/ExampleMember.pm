package MyProject::Schema::Default::ExampleMember;
use MyProject qw/-b MyProject::Schema::Default -s -w/;

__PACKAGE__->table('example_members')
->add_columns(
    id           => {-t => 'serial'},
    name         => {-t => 'varchar', -s => 10, -l => '名前'},
    email        => {-t => 'varchar', -s => 255, -l => 'メールアドレス', -v => [qw/eml/],
        -x => {charset => 'utf8'}}, #ignore upper/lower case
    gender       => {-t => 'tinyint', -s => 1, -l => '性別', -e => [[qw/1 男/], [qw/2 女/]]},
    birthday     => {-t => 'date', -l => '誕生日', -i => 'date'},
    tel          => {-t => 'varchar', -s => 20, -l => '電話番号', -v => [qw/tel/]},
    hobbies      => {-t => 'varchar', -s => 7, -l => '趣味', -i => 'colon_sv',
        -e => [[qw/1 スポーツ sports/], [qw/2 映画 movie/], [qw/3 音楽 music/]]},
    money        => {-t => 'int', -u => 1, -l => '所持金', -n => 1, -v => [qw/range(1<=99999)/]},
    lock_version => {-t => 'tinyint', -u => 1, -d => 1},
    created_at   => {-t => 'datetime'},
    updated_at   => {-t => 'datetime'},
)
->table_option({engine => 'InnoDB'})
->primary_key([qw/id/])
->has_many(entry_members => 'ExampleEntryMember', {-on => 'member_id'})
->many_to_many(entries => 'entry_members' => 'entry');

1;
