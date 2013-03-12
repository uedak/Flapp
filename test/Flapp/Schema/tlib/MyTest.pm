package MyTest;
use Test::More;
use strict;
use warnings;
use Cwd;
use FindBin;

sub setup {
    my($self, $proj) = @_;
    
    eval("use $_"), $@ && plan(skip_all => "$_ not installed") for qw/DBI/;
    my $cfg = $proj->config->DB->Default->dsn->[0];
    plan(skip_all => qq{Invalid dsn "$cfg->[0]"}) if $cfg->[0] !~ /^(dbi:\w+:)(\w+)(.+)\z/;
    my $dbh = DBI->connect($1.$3, $cfg->[1], $cfg->[2]) || die $DBI::errstr;
    my $sto = $proj->schema->storage;
    my $dbn = $sto->dbname;
    eval{ $dbh->do($sto->create_database_sql) };
    plan(skip_all => qq{Can't create database "$dbn"}) if $@;
    plan('no_plan');
    ($dbh, $dbn);
}

sub migrate {
    my($self, $proj) = @_;
    my $ddl = $proj->schema->storage->create_ddl;
    print $proj->Util->debug_line;
    while($ddl =~ s/^\s*(.*?);//s){
        print "$1;\n".$proj->Util->debug_line;
        $proj->dbh->do("$1");
    }
}

1;
