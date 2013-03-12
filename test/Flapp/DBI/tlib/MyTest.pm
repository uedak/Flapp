package MyTest;
use Test::More;
use strict;
use warnings;

sub setup {
    my($self, $proj) = @_;
    
    eval("use $_"), $@ && plan(skip_all => "$_ not installed") for qw/DBI DBD::mysql/;
    my $cfg = $proj->Config->src($proj->config);
    my $dsn = $cfg->{DB}{Default}{dsn};
    $dsn->[1] = $proj->Util->deep_copy($dsn->[0]); #as slave
    $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
    
    $cfg = $proj->config->DB->Default->dsn->[0];
    if($cfg->[0] !~ /^(dbi:mysql:)(\w+)(.+)\z/i){
        plan(skip_all => 'No database config for mysql');
    }
    my $dbh = DBI->connect($1.$3, $cfg->[1], $cfg->[2]) || die $DBI::errstr;
    if(grep{ $_->[0] eq $2 } @{$dbh->selectall_arrayref('show databases')}){
        plan(skip_all => qq{Database "$2" already exists.});
    }
    plan('no_plan');
    my $dbn = $2;
    
    $dbh->prepare("create database $dbn DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;")->execute;
    
    ($dbh, $dbn);
}

1;
