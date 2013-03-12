package Flapp::App::Cmd::Tool::Controller::DB;
use Flapp qw/-b Flapp::App::Cmd::Controller -m -s -w/;
use Cwd;

sub create_ddl :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    my $db = $c->args->{DB} || 'Default';
    my $dir = $c->project_root."/db/migrate/$db";
    my $f = '001_init_schema.sql';
    if(-f "$dir/$f"){
        print qq{Overwrite? "$dir/$f" [y] };
        return if <STDIN> !~ /^y?$/;
    }
    
    my $ddl = $proj->schema($db)->storage->create_ddl;
    $proj->OS->mkdir_p($dir) if !-d $dir;
    $proj->OS->cat($ddl, '>', "$dir/$f") || die "$!($dir/$f)";
    print "create: $dir/$f\n";
}

sub dump :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    my $db = $c->args->{DB} ||= 'Default';
    my($buf, $t, $f, %opt);
    
    (print "Table name? [] ") && chop($t = <STDIN>) if !($t = $c->args->{TABLE});
    if(!($f = $c->args->{DATA})){
        $f = Cwd::abs_path('.')."/$t.tsv";
        $f = $buf if (print "Data file? [$f] ") && chop($buf = <STDIN>) && $buf ne '';
    }
    $opt{header} = $c->args->{HEADER} if exists $c->args->{HEADER};
    
    my $cnt = $proj->schema($db)->storage->dump_tsv($t => $f, \%opt);
    print "$t ... ok($cnt)\n";
}

sub load :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    my $db = $c->args->{DB} ||= 'Default';
    my($buf, $t, $f, $m, %opt);
    
    (print "Table name? [] ") && chop($t = <STDIN>) if !($t = $c->args->{TABLE});
    if(!($f = $c->args->{DATA})){
        $f = Cwd::abs_path('.')."/$t.tsv";
        print "Data file? [$f] ";
        $f = $buf if chop($buf = <STDIN>) && $buf ne '';
    }
    if(!($m = $c->args->{MODE})){
        $m = 'truncate';
        $m = $buf if (print "Mode? (truncate|append) [$m] ") && chop($buf = <STDIN>) && $buf ne '';
    }
    $opt{truncate} = $m eq 'truncate' ? 1 : 0;
    die 'Truncate table not allowed' if $opt{truncate} && !$c->app_config->allow_db_truncate;
    $opt{header} = $c->args->{HEADER} if exists $c->args->{HEADER};
    
    my $cnt = $proj->schema($db)->storage->load_tsv($f => $t, \%opt);
    print "$t ... ok($cnt)\n";
}

sub load_defaults :Action {
    my($self, $c) = @_;
    die 'Truncate table not allowed' if !$c->app_config->allow_db_truncate;
    my $proj = $c->project;
    my $db = $c->args->{DB} ||= 'Default';
    my $dir = $proj->project_root."/db/load_defaults/$db";
    my $ls = $proj->OS->ls($dir) || die "$!($dir)";
    my $env = $proj->env;
    my $sto = $proj->schema($db)->storage;
    my $sql;
    
    $sto->dbh->do($sql) if ($sql = $sto->disable_constraint_sql);
    foreach(@$ls){
        next if !-f "$dir/$_" || -f "$dir/$_.$env";
        (my($table) = /^(\w+)\.tsv(\.$env)?\z/) || next;
        
        print qq(Load? "$dir/$_" [y] );
        next if !$c->args->{FORCE} && (<STDIN> !~ /^y?$/);
        print "\n" if $c->args->{FORCE};
        
        my $cnt = $sto->load_tsv("$dir/$_" => $table);
        print "$table ... ok($cnt)\n";
    }
    $sto->dbh->do($sql) if ($sql = $sto->enable_constraint_sql);
}

sub migrate :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    my $db = $c->args->{DB} || 'Default';
    my $dir = $c->project_root."/db/migrate/$db";
    my $sch = $proj->schema($db)->SchemaInfo;
    my $dbh = $proj->dbh($db);
    
    my %v2sql;
    foreach(@{$proj->OS->ls($dir) || die "$!($dir)"}){
        /\.sql\z/ || next;
        /^([0-9]{3})_/ && $1 ne '000' || die qq{Invalid sql: "$_" in "$dir"};
        die qq{Can't use same version "$_" and "$v2sql{$1}" in "$dir"} if $v2sql{$1};
        $v2sql{$1} = $_;
    }
    
    if($c->args->{CLEANUP}){
        die 'Truncate table not allowed' if !$c->app_config->allow_db_truncate;
        print "Drop all tables. Are you sure? [n] ";
        return if <STDIN> !~ /^y$/;
        my(@sql, $sql);
        push @sql, $sql if ($sql = $sch->storage->disable_constraint_sql);
        push @sql, map{ "DROP TABLE $_\n" } $dbh->tables;
        push @sql, $sql if ($sql = $sch->storage->enable_constraint_sql);
        (print "\n$_") && $dbh->do($_) for @sql;
    }
    
    my %v;
    eval{ $v{$_->version} = 1 for @{$sch->search} };
    foreach(sort keys %v2sql){
        last if defined $c->args->{VERSION} && int($_) > int($c->args->{VERSION});
        next if $v{$_};
        
        print qq{Execute? "$dir/$v2sql{$_}" [y] };
        next if !$c->args->{FORCE} && (<STDIN> !~ /^y?$/);
        print "\n" if $c->args->{FORCE};
        
        $proj->OS->cat(my $buf, '<', "$dir/$v2sql{$_}") || die "$!($dir/$v2sql{$_})";
        $buf =~ s%/\*.*?\*/%%sg;
        $buf =~ s/^[\t\n\r ]*--.*\n//mg;
        while($buf =~ s/^[\t\n\r ]*(.*?);//s){
            print "$1;\n\n";
            $dbh->do("$1");
        }
        die '?' if $buf =~ /[^\t\n\r ]/;
        $sch->new({version => $_})->insert;
    }
}

sub show_create_database_sql :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    
    my %host;
    foreach my $db (sort keys %{$proj->config->DB}){
        my $s = $proj->schema($db)->storage;
        my $db = $host{$s->host}->{$s->dbname} ||= {sql => $s->create_database_sql};
        $db->{users}{$s->user} = $s->create_user_sql;
    }
    
    my $sql = '';
    foreach my $host (sort keys %host){
        $sql .= "\n" if $sql;
        $sql .= "### $host ###\n";
        foreach my $db (values %{$host{$host}}){
            $sql .= $db->{sql};
            $sql .= $_ for values %{$db->{users}};
        }
    }
    print $sql;
}

1;
