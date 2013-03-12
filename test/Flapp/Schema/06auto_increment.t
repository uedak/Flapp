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

$proj->begin;
eval{
    MyTest->migrate($proj);
    my $dbh = $se->storage->dbh;
    $dbh->txn_log('xxx' => 'txn');
    
    my $e1 = $se->new;
    $e1->content({});
    
    is $e1->id, undef;
    is $e1->content->entry_id, undef;
    
    $e1->insert;
    is $e1->id, 1;
    is $e1->content->entry_id, 1;
    
    $se->new->insert;
    
    $dbh->flush_txn_log;
    my $log = $proj->logger('txn');
    $proj->OS->cat(my $buf, '<', $log->path);
    like $buf, qr/^\d\d:\d\d:\d\d\txxx
\QINSERT INTO example_entries (id, created_at, updated_at, lock_version) VALUES (?, ?, ?, ?)\E
\t1:\t1\t[0-9\- :]+\t[0-9\- :]+\t1
\t2:\t2\t[0-9\- :]+\t[0-9\- :]+\t1

\z/;
    $proj->OS->rm_rf($proj->config->log_dir);
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;
