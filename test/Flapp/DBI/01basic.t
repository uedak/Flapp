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

eval{
    {
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], 0;
        $proj->end;
        
        $proj->begin;
        ok my $dbh2 = $proj->dbh;
        is $dbh2->{private_flapp_dbh}[1], 1;
        $proj->end;
        
        $proj->begin;
        ok my $dbh3 = $proj->dbh;
        is $dbh3->{private_flapp_dbh}[1], 0;
        is $dbh3, $dbh;
        $proj->end;
        
        $proj->begin;
        ok my $dbh4 = $proj->dbh;
        is $dbh4->{private_flapp_dbh}[1], 1;
        is $dbh4, $dbh2;
        $proj->end;
        
        if($DBH->{Driver}->{Name} eq 'mysql'){
            my @p = grep{ ($_->[3] || '') eq $DBN } @{$dbh->selectall_arrayref('show processlist')};
            is int(@p), 2;
        }
        
        $dbh->do('create table test(id serial, name varchar(10))');
    }
    
    if($DBH->{Driver}->{Name} eq 'mysql'){
        foreach my $i (0, 1){
            $proj->begin;
            ok my $dbh = $proj->dbh;
            is $dbh->{private_flapp_dbh}[1], $i;
            
            is $dbh->master->{mysql_insertid}, 0;
            is $dbh->prepare('insert into test(name) values(?)')->execute('aaa'), 1;
            is $dbh->master->{mysql_insertid}, 1;
            
            $dbh->prepare('truncate table test')->execute;
            $proj->end;
        }
    }
    
    foreach my $i (0, 1){
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], $i;
        
        is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
        $dbh->prepare('select name from test where id = ?')->execute(1);
        is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
        is $dbh->prepare('insert into test(name) values(?)')->execute('aaa'), 1;
        is $dbh->{private_flapp_dbh}[0]{use_master}, $i;
        
        $dbh->prepare('truncate table test')->execute;
        $proj->end;
    }
    
    {
        foreach my $i (0, 1){
            $proj->begin;
            ok my $dbh = $proj->dbh;
            is $dbh->{private_flapp_dbh}[1], $i;
            
            is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
            $dbh->prepare('select name from test where id = ?')->execute(1);
            is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
            $dbh->prepare('select name from test where id = ? for update')->execute(1);
            is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
            $proj->end;
        }
        
        my $cfg = $proj->Config->src($proj->config);
        $_->[3]{AutoCommit} = 0 for @{$cfg->{DB}{Default}{dsn}};
        local $proj->_global_->{dbh_pool} = {};
        local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
        
        foreach my $i (0, 1){
            $proj->begin;
            ok my $dbh = $proj->dbh;
            is $dbh->{private_flapp_dbh}[1], $i;
            
            is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
            $dbh->prepare('select name from test where id = ?')->execute(1);
            is $dbh->{private_flapp_dbh}[0]{use_master}, 0;
            $dbh->prepare('select name from test where id = ? for update')->execute(1);
            is $dbh->{private_flapp_dbh}[0]{use_master}, $i;
            $proj->end;
        }
        $proj->dbh(Default => $_)->disconnect for 0, 1;
    }
    
    my $log = $proj->logger('txn');
    foreach my $i (0, 1){
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], $i;
        
        $dbh->txn_log('xxx' => 'txn');
        my $sth = $dbh->prepare('insert into test(name) values(?)');
        is $sth->execute('aaa'), 1;
        is $sth->execute('bbb'), 1;
        $dbh->do('delete from test');
        $proj->end;
        
        $proj->OS->cat(my $buf, '<', $log->path);
        like $buf, qr/^\d\d:\d\d:\d\d\txxx
insert into test\(name\) values\(\?\)
\t1:\taaa
\t2:\tbbb
delete from test
\t3:

\z/;
        $proj->OS->cat('', '>', $log->path);
    }
    
    foreach my $i (0, 1){
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], $i;
        
        $dbh->txn_log('xxx' => 'txn');
        $dbh->begin_work;
        my $sth = $dbh->prepare('insert into test(name) values(?)');
        is $sth->execute('aaa'), 1;
        is $sth->execute('bbb'), 1;
        $dbh->do('delete from test');
        $dbh->commit;
        $proj->end;
        
        $proj->OS->cat(my $buf, '<', $log->path);
        like $buf, qr/^\d\d:\d\d:\d\d\txxx
insert into test\(name\) values\(\?\)
\t1:\taaa
\t2:\tbbb
delete from test
\t3:

\z/;
        $proj->OS->cat('', '>', $log->path);
    }
    
    foreach my $i (0, 1){
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], $i;
        
        $dbh->txn_log('xxx' => 'txn');
        $dbh->begin_work;
        my $sth = $dbh->prepare('insert into test(name) values(?)');
        is $sth->execute('aaa'), 1;
        $dbh->do('delete from test');
        $dbh->rollback;
        $proj->end;
        $proj->OS->cat(my $buf, '<', $log->path);
        is $buf, '';
    }
    $proj->OS->rm_rf($proj->config->log_dir);
};

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;
