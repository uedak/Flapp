use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use lib Cwd::abs_path("$FindBin::Bin/tlib");
use MyProject qw/-s -w/;
use utf8;
$Flapp::UTF8 = 2;
use MyTest;
my $proj = 'MyProject';
my($DBH, $DBN) = MyTest->setup($proj);
ok $DBN;

eval{
    $proj->begin;
    ok my $dbh = $proj->dbh;
    is $dbh->{private_flapp_dbh}[1], 0;
    $dbh->do('CREATE TABLE test(name VARCHAR(10), `名前` VARCHAR(10))');
    $dbh->do('INSERT INTO test VALUES(?, ?)', undef, 'a', 'あ');
    
    my $sql = 'SELECT * FROM test';
    my($sth, $r);
    ($sth = $dbh->prepare("$sql limit 1"))->execute;
    is_deeply $sth->fetch, ['a', 'あ'];
    
    ($sth = $dbh->prepare("$sql limit 1"))->execute;
    is_deeply $sth->fetchrow_arrayref, ['a', 'あ'];
    
    ($sth = $dbh->prepare("$sql limit 1"))->execute;
    is_deeply $sth->fetchrow_hashref, {name => 'a', 名前 => 'あ'};
    
    is_deeply $dbh->selectall_arrayref($sql), [['a', 'あ']];
    is_deeply $dbh->selectall_arrayref($sql, {Slice => {}}), [{name => 'a', 名前 => 'あ'}];
    
    is_deeply $dbh->selectall_hashref($sql, 1), {a => {name => 'a', 名前 => 'あ'}};
    is_deeply $dbh->selectall_hashref($sql, 'name'), {a => {name => 'a', 名前 => 'あ'}};
    is_deeply $dbh->selectall_hashref($sql, 2), {あ => {name => 'a', 名前 => 'あ'}};
    #is_deeply $dbh->selectall_hashref($sql, '名前'), {あ => {name => 'a', 名前 => 'あ'}};
    is_deeply $dbh->selectall_hashref($sql, [1, 2]), {a => {あ => {name => 'a', 名前 => "あ"}}};
    #is_deeply $dbh->selectall_hashref($sql, [qw/name 名前/]),
    #    {a => {あ => {name => 'a', 名前 => "あ"}}};
    
    is_deeply $dbh->selectcol_arrayref($sql, {Columns => [2]}), ['あ'];
    is_deeply [$dbh->selectrow_array($sql)], ['a', 'あ'];
    is_deeply $dbh->selectrow_arrayref($sql), ['a', 'あ'];
    is_deeply $dbh->selectrow_hashref($sql), {name => 'a', 名前 => 'あ'};
    
    $proj->end;
};

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;
