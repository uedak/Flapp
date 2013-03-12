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
    $proj->begin;
    ok my $dbh0 = $proj->dbh;
    is $dbh0->{private_flapp_dbh}[1], 0;
    $dbh0->do('create table test(id serial, name varchar(10))');
    $proj->end;
    
    $proj->begin;
    ok my $dbh1 = $proj->dbh;
    is $dbh1->{private_flapp_dbh}[1], 1;
    $proj->end;
    
    my $killall;
    if($DBH->{Driver}->{Name} eq 'mysql'){
        $killall = sub{
            $DBH->do("kill $_->[0]") for grep{ ($_->[3] || '') eq $DBN }
                @{$DBH->selectall_arrayref('show processlist')};
            while(1){
                select undef, undef, undef, 0.01;
                last if !grep{ $_ && $_->ping } @{$proj->_global_->{dbh_pool}{Default}{DBHS}};
            }
        };
    }
    
    {
        $killall->();
        
        foreach my $i (0, 1){
            $proj->begin;
            ok my $dbh = $proj->dbh;
            ok !eval{ $dbh->begin_work };
            $proj->end;
        }
        
        foreach my $i (0, 1){
            $proj->begin;
            ok my $dbh = $proj->dbh;
            $dbh->auto_reconnect(1);
            is ${tied *STDERR}, '';
            ok $dbh->begin_work;
            #like ${tied *STDERR}, qr/^DBH reconnected \(Default:0\)/;
            ${tied *STDERR} = '';
            ok $dbh->rollback;
            $proj->end;
            
            $killall->();
        }
        
        my $sql = 'select * from test';
        my($dbh, $sth);
        foreach my $i (0, 1){
            is ${tied *STDERR}, '';
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is_deeply $dbh->selectall_arrayref($sql), [];
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is_deeply $dbh->selectall_hashref($sql, 1), {};
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is_deeply $dbh->selectcol_arrayref($sql), [];
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is_deeply [$dbh->selectrow_array($sql)], [];
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is $dbh->selectrow_arrayref($sql), undef;
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            is $dbh->selectrow_hashref($sql), undef;
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            $sth = $dbh->prepare($sql);
            is ${tied *STDERR}, '';
            $sth->execute;
            is_deeply $sth->fetchrow_arrayref, undef;
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
            
            $proj->begin;
            ok $dbh = $proj->dbh('Default', $i);
            $dbh->auto_reconnect(1);
            $sth = $dbh->prepare_cached($sql);
            is ${tied *STDERR}, '';
            $sth->execute;
            is_deeply $sth->fetchrow_arrayref, undef;
            #like ${tied *STDERR}, qr/^\QDBH reconnected (Default:$i)\E/;
            ${tied *STDERR} = '';
            $killall->();
            $proj->end;
        }
    }
    
    { #Can't connect master
        my $cfg = $proj->Config->src($proj->config);
        $cfg->{DB}{Default}{dsn}[0][1] = '?'; #master
        local $proj->_global_->{dbh_pool} = {};
        local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
        ok !eval{ $proj->dbh };
        ${tied *STDERR} = '';
    }
    
    { #Can't connect slave
        my $cfg = $proj->Config->src($proj->config);
        $cfg->{DB}{Default}{dsn}[1][1] = '?'; #slave
        $cfg->{DB}{Default}{dsn}[1][3]{PrintError} = 0;
        local $proj->_global_->{dbh_pool} = {};
        local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
        is ${tied *STDERR}, '';
        ok $proj->dbh('Default', 1);
        like ${tied *STDERR}, qr/^Trying master dbh because slave\(Default:1\) connection failed:/;
        ${tied *STDERR} = '';
    }
    
    { #Can't connect master on auto_reconnect
        local $proj->_global_->{dbh_pool} = {};
        $proj->begin;
        is ${tied *STDERR}, '';
        my $dbh = $proj->dbh;
        my $sql = 'select * from test';
        is_deeply $dbh->selectall_arrayref($sql), [];
        
        my $cfg = $proj->Config->src($proj->config);
        $cfg->{DB}{Default}{dsn}[0][1] = '?'; #master
        local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
        $killall->();
        ok !eval{ $dbh->prepare($sql)->execute };
        ${tied *STDERR} = '';
        
        $proj->end;
    }
    
    { #Can't connect slave on auto_reconnect
        local $::ENV{FLAPP_DEBUG} = 1;
        local $proj->_global_->{dbh_pool} = {};
        
        $proj->begin;
        my $dbh = $proj->dbh;
        $proj->end;
        
        $proj->begin;
        $dbh = $proj->dbh;
        
        my $sql = 'select * from test';
        foreach my $i (0, 1){
            if($i){
                $dbh->disconnect;
                $dbh->auto_reconnect(1);
            }
            
            ok my $sth = $dbh->prepare($sql);
            is ${tied *STDERR}, '';
            ok $sth->execute;
            like ${tied *STDERR}, qr/^-+\n\Q$(Default:1)->execute("$sql")\E/;
            ${tied *STDERR} = '';
            is $sth->fetchrow_arrayref, undef;
            is ${tied *STDERR}, '';
        }
        
        my $cfg = $proj->Config->src($proj->config);
        $cfg->{DB}{Default}{dsn}[1][1] = '?'; #slave
        $cfg->{DB}{Default}{dsn}[1][3]{PrintError} = 0;
        local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
        
        $dbh->disconnect;
        $dbh->auto_reconnect(1);
        ok my $sth = $dbh->prepare($sql);
        is ${tied *STDERR}, '';
        ok $sth->execute;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:1)->execute("$sql")\E/;
        like ${tied *STDERR}, qr/Trying master dbh because slave\(Default:1\) connection failed:/;
        #like ${tied *STDERR}, qr/DBH reconnected \(Default:1\)/;
        ${tied *STDERR} = '';
        is $sth->fetchrow_arrayref, undef;
        is ${tied *STDERR}, '';
        
        ok $sth->execute;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->execute("$sql")\E/;
        ${tied *STDERR} = '';
        
        ok $proj->dbh('Default', 0)->prepare($sql)->execute;
        like ${tied *STDERR}, qr/^-+\n\Q$(Default:0)->execute("$sql")\E/;
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
