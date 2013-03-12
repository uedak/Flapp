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
my $dbst = qr{
 at Flapp::DBI::db::__ANON__\(.*02trace\.t \d+\)
 at \(eval\)\(.*02trace\.t \d+\)
-+\n\z};
my $stst = qr{
 at Flapp::DBI::st::execute\(.*02trace\.t \d+\)
 at \(eval\)\(.*02trace\.t \d+\)
-+\n\z};

eval{
    local $::ENV{FLAPP_DEBUG} = 2;
    
    
    {
        $proj->begin;
        ok my $dbh = $proj->dbh;
        
        my $sql = "create table test(id serial, name varchar(10))";
        $dbh->do($sql);
        like ${tied *STDERR}, qr{^-+\n\Q$(Default:0)->do("$sql")\E$dbst};
        ${tied *STDERR} = '';
        
        $dbh->do('insert into test(name) values(?)', undef, 'foo');
        like ${tied *STDERR},
            qr{^-+\n\Q$(Default:0)->do("insert into test(name) values('foo')")\E$dbst};
        ${tied *STDERR} = '';
        
        $proj->end;
    }
    
    {
        $proj->begin;
        ok my $dbh = $proj->dbh;
        
        my $sql = 'select * from test';
        foreach my $i (1, 0){
            $dbh->selectall_arrayref($sql);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->selectall_arrayref("$sql")\E$dbst};
            ${tied *STDERR} = '';
            
            $dbh->selectall_hashref($sql, 1);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->execute("$sql")\E};
            ${tied *STDERR} = '';
            
            $dbh->selectcol_arrayref($sql);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->execute("$sql")\E};
            ${tied *STDERR} = '';
            
            $dbh->selectrow_array($sql);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->selectrow_array("$sql")\E$dbst};
            ${tied *STDERR} = '';
            
            $dbh->selectrow_arrayref($sql);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->selectrow_arrayref("$sql")\E$dbst};
            ${tied *STDERR} = '';
            
            $dbh->selectrow_hashref($sql);
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->execute("$sql")\E};
            ${tied *STDERR} = '';
            
            my $sth = $dbh->prepare($sql);
            is ${tied *STDERR}, '';
            $sth->execute;
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->execute("$sql")\E$stst};
            ${tied *STDERR} = '';
            
            $sth = $dbh->prepare_cached($sql);
            is ${tied *STDERR}, '';
            $sth->execute;
            like ${tied *STDERR}, qr{^-+\n\Q$(Default:$i)->execute("$sql")\E$stst};
            ${tied *STDERR} = '';
            
            last if !$i;
            $dbh->do('insert into test(name) values(?)', undef, 'bar');
            like ${tied *STDERR},
                qr{^-+\n\Q$(Default:0)->do("insert into test(name) values('bar')")\E$dbst};
            ${tied *STDERR} = '';
        }
        
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
