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

tie *STDERR, 'Capture';
eval{
    {
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], 0;
        $dbh->do('create table test(id serial, name varchar(10)) ENGINE=InnoDB');
        $proj->end;
    }
    local $::ENV{FLAPP_DEBUG} = 1;
    {
        $proj->begin;
        ok my $dbh = $proj->dbh;
        is $dbh->{private_flapp_dbh}[1], 1;
        
        is ${tied *STDERR}, '';
        is $dbh->txn_do(sub{
            $dbh->prepare('insert into test values(?, ?)')->execute(1, 'A');
        }), 1;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->begin_work()\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->execute("insert into test values('1', 'A')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->commit()\E/;
        is_deeply $dbh->selectrow_arrayref('select count(*) from test'), [1];
        ${tied *STDERR} = '';
        
        ok !eval{ $dbh->txn_do(sub{
            my $sth = $dbh->prepare('insert into test values(?, ?)');
            $sth->execute(2, 'B');
            $sth->execute(2, 'C');
        }) };
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->begin_work()\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->execute("insert into test values('2', 'B')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->execute("insert into test values('2', 'C')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->rollback()\E/;
        is_deeply $dbh->selectrow_arrayref('select count(*) from test'), [1];
        ${tied *STDERR} = '';
        
        is $dbh->txn_do(sub{
            my $sth = $dbh->prepare('insert into test values(?, ?)');
            $sth->execute(2, 'B');
            $dbh->txn_do(sub{
                $sth->execute(3, 'C');
            })
        }), 1;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->begin_work()\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->execute("insert into test values('2', 'B')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->execute("insert into test values('3', 'C')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->commit()\E/;
        is_deeply $dbh->selectrow_arrayref('select count(*) from test'), [3];
        ${tied *STDERR} = '';
        
        is $dbh->txn_do(sub{
            $dbh->do('insert into test values(?, ?)', undef, 4, 'D');
            $dbh->rollback;
        }), 1;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->begin_work()\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->do("insert into test values('4', 'D')")\E/;
        like ${tied *STDERR}, qr/\Q$(Default:0)->rollback()\E/;
        is_deeply $dbh->selectrow_arrayref('select count(*) from test'), [3];
        ${tied *STDERR} = '';
        
        
        
        is $dbh->no_txn_do(sub{
            my $sth = $dbh->prepare('insert into test values(?, ?)');
            $sth->execute(4, 'D');
        }), 1;
        like ${tied *STDERR}, qr/\Q$(Default:1)->execute("insert into test values('4', 'D')")\E/;
        is_deeply $dbh->selectrow_arrayref('select count(*) from test'), [4];
        ${tied *STDERR} = '';
        
        $proj->end;
    }
};
untie *STDERR;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;

package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }
