use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use lib Cwd::abs_path("$FindBin::Bin/tlib");
use strict;
use warnings;

use MyProject;
use MyTest;
my $proj = 'MyProject';
my($DBH, $DBN) = MyTest->setup($proj);
ok $DBN;

is my $se = $proj->schema->ExampleEntry,
    'MyProject::Schema::Default::ExampleEntry';
is my $sec = $proj->schema->ExampleEntryContent,
    'MyProject::Schema::Default::ExampleEntryContent';
is my $sem = $proj->schema->ExampleEntryMember,
    'MyProject::Schema::Default::ExampleEntryMember';
is my $sm = $proj->schema->ExampleMember,
    'MyProject::Schema::Default::ExampleMember';

$proj->begin;
eval{
    MyTest->migrate($proj);
    
    {
        local $proj->schema_cache->{$proj->schema} = {ExampleEntry => {}};
        my $e = $se->new;
        eval{ $e->txn_do(sub{ $e->insert && die }) };
        is $e->id, 1;
        ok !$e->in_storage;
        ok !$se->find(1);
    }
    
    {
        local $Flapp::NOW = my $m48 = '2012-07-13T18:48:00+0900';
        local $proj->schema_cache->{$proj->schema} = {ExampleEntry => {}};
        my $e = $se->new->insert;
        is $se->find(2), $e;
        is $e->lock_version, 1;
        is $e->updated_at, $Flapp::NOW;
        
        $Flapp::NOW = '2012-07-13T18:49:00+0900';
        $proj->dbh->begin_work;
        $e->id(3)->update;
        $proj->dbh->rollback;
        is $e->lock_version, 1;
        is $e->updated_at, $m48;
        is $se->find(2), $e;
        is $se->find(3), undef;
    }
    
    {
        local $proj->schema_cache->{$proj->schema} = {ExampleEntry => {}};
        my $e = $se->new->insert;
        is $se->find(3), $e;
        eval{ $e->txn_do(sub{ $e->delete && die }) };
        ok $e->in_storage;
        is $se->find(3), $e;
    }
    
    {
        local $proj->schema_cache->{$proj->schema} = {ExampleEntry => {}};
        ok my $e2 = $se->find(2);
        ok my $e3 = $se->find(3);
        eval{ $se->txn_do(sub{
            $e3->id(4)->update->delete && $e2->id(3)->update->delete && die
        }) };
        is $se->find(2), $e2;
        is $se->find(3), $e3;
    }
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;
