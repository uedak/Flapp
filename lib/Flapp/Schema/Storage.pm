package Flapp::Schema::Storage;
use Flapp qw/-b Flapp::Object -m -r -s -w/;

use constant REG_QT => qr/'(?:\\.|''|[^\\']+)*'|"(?:\\.|""|[^\\"]+)*"/s;

use constant REG_PR => do{
    my $qt = REG_QT;
    my $pr;
    use re 'eval';
    $pr = qr/\((?:[^"'()]+|$qt|(??{$pr}))*\)/;
};

sub DB { ${$_[0]} }

sub asterisk_for { defined $_[2] && $_[2] ne '' ? "$_[2].*" : '*' }

sub config {
    my $self = shift;
    $self->project->config->DB->$$self;
}

sub dbh {
    my $self = shift;
    $self->project->dbh($$self);
}

sub dbname {
    my $dsn = shift->master_dsn;
    $dsn->[0] =~ /^dbi:[0-9A-Za-z_]+:([0-9A-Za-z_]+)/ && $1 || die qq{Can't parse dsn: "$dsn->[0]"};
}

sub deflate_colon_sv {
    my @v = grep{ defined $_ && $_ ne '' } @{$_[1]};
    @v ? ':'.join(':', @v).':' : ''
}

sub deflate_date { $_[1]->ymd }

sub deflate_time { $_[1]->ymd.' '.$_[1]->hms }

sub disable_constraint_sql { '' }

sub enable_constraint_sql { '' }

sub host { shift->master_dsn->[0] =~ /host=([^\t\n\r ;]+)/ && $1 || 'localhost' }

sub inflate_colon_sv { [$_[1] =~ /([^:]+)/g] }

sub inflate_date { shift->project->Date->parse(shift) }

sub inflate_time { shift->project->Time->parse(shift) }

sub interpolate_sql {
    my($self, $sr, $xr) = @_;
    my $i = -1;
    my @i;
    ref $_ ? push(@i, ++$i) : ++$i for @$xr;
    return if !@i;
    $i = -1;
    my @ref;
    while($$sr =~ /\?/g){
        next if ++$i < $i[0];
        unshift @ref, [shift @i, pos($$sr) - 1];
        last if !@i;
    }
    pos $$sr = 0;
    $self->interpolate_sql_for($sr, $xr, @$_) for @ref;
}

sub interpolate_sql_for {
    my($self, $sr, $xr, $i, $pos) = @_;
    my $r = $xr->[$i];
    if(ref $r eq 'ARRAY'){
        if(substr($$sr, $pos - 1, 3) ne '(?)'){
            die qq{Placeholder for ARRAY is not enclosed in parentheses: $$sr}
        }
        if(@$r){
            substr($$sr, $pos, 1) = join(',', map{ '?' } @$r);
        }else{
            substr($$sr, $pos - 1, 3) = '(NULL) AND 1 = 0';
        }
        splice @$xr, $i, 1, @$r;
    }
}

sub master_dsn { shift->config->dsn->[0] }

sub mysql { shift->MySQL }

sub new { bless \"$_[1]", $_[0] }

sub on_add_column {
    my($self, $sch, $ci) = @_;
    my $t = $self->typeof($ci);
    my $dt = ($t eq 'date' || $t eq 'time');
    $ci->{-i} ||= $t if $dt;
    
    my @v = $ci->{-v} ? $self->project->validate_options(@{$ci->{-v}}) : ();
    my %v = @v ? map{ $_->[0] => 1 } @v : ();
    unshift @v, [range => '0<='] if $ci->{-u} && !$v{range};
    unshift @v, [enum => $ci->{-e}] if $ci->{-e} && !$v{enum};
    unshift @v, [size => "<=$ci->{-s}"] if $ci->{-s} && $t eq 'str' && !$ci->{-i} && !$v{size};
    unshift @v, [$t] if ($dt || $t eq 'int' && !$v{range}) && !$v{$t};
    unshift @v, $ci->{-e} ? ['sel'] : ['nn'] if !$ci->{-n} && !$v{nn} && !$v{sel};
    $ci->{-v} = \@v if @v;
}

sub password {
    my $pw = shift->master_dsn->[2];
    defined $pw ? $pw : '';
}

sub placeholder_for { '?' }

sub rbs { shift->dbh->rbs }

sub search {
    my($self, $sch, $cnd, $opt) = @_;
    my($rows, $page) = $self->search_rows_and_page($sch, $opt, wantarray);
    my $s = $self->search_sql($sch, $cnd, $opt, $rows, $page, wantarray);
    my $dbh = $self->dbh;
    (my $sth = $dbh->prepare_cached($s->{sql}) || die $dbh->errstr)->execute(@{$s->{x}});
    my(@r, $r);
    if($s->{j}){
        $self->prepare_rfetch($sth, $s->{j});
        $self->rfetch($r, $s->{j}, undef, \@r) while ($r = $sth->fetchrow_arrayref);
    }else{
        push @r, $sch->instantiate($r) while ($r = $sth->fetchrow_hashref);
    }
    return \@r if !wantarray;
    
    my $cnt = (@r ? @r < $rows : $page == 1) ? $rows * ($page - 1) + @r : do{
        ($sth = $dbh->prepare_cached($s->{cnt}) || die $dbh->errstr)->execute(@{$s->{sx}});
        $sth->fetchall_arrayref->[0][0];
    };
    (\@r, $self->project->Pager->new($cnt, $rows, $page));
}

sub search_rows_and_page {
    my($self, $sch, $opt, $wa) = @_;
    my($rows, $page) = (@$opt{qw/rows page/});
    if(defined $rows || $wa){
        $rows = $sch->DEFAULT_SEARCH_ROWS if !$rows || $rows =~ /[^0-9]/;
        my $max = $sch->MAX_SEARCH_ROWS;
        warn "Rows($rows) exceeded MAX_SEARCH_ROWS(".($rows = $max).')' if $max && $rows > $max;
    }
    $page = 1 if !$page || $page =~ /[^0-9]/;
    ($rows, $page);
}

sub search_sql {
    my($self, $sch, $cnd, $opt, $rows, $page, $wa) = @_;
    my($sp, $src, $whr, $ord, $ji, $mj, @cx, @sx, @wx, @ox, $s, %s) = (' ', '', '', '');
    my $t = $opt->{from} || $sch->table || die "No table for $sch";
    if(ref $t){ #experimental
        ($t, @sx) = @$t;
        $self->interpolate_sql(\$t, \@sx) if @sx;
    }
    my $me = defined $opt->{-as} ? $opt->{-as} : '';
    my $cols = $opt->{select} && $self->sql_cols($opt->{select}, \@cx) || '*';
    
    if($opt->{join} && %{$opt->{join}}){
        $me = 'me' if $me eq '';
        ($sp, $ji) = ("\n", {});
        $s{j} = $ji->{$me} = {-as => $me, depth => 1, schema => $sch};
        $self->parse_join($opt->{join} => $ji, $ji->{$me}, \$src, \@sx);
        ($mj = $_->{_multi}) && last for values %$ji;
        die q{Can't search group_by with multiple-join} if $mj && $opt->{group_by};
        $self->parse_join_columns(\$cols, $ji, $me);
    }else{
        $cols =~ s/(\(\s*\*\s*\)|(?:\S+\.)?\*)/
            ($1 eq '*' || $1 eq "$me.*" || $1 eq '*.*') ? $self->asterisk_for($t, $me) : $1/eg;
    }
    
    $t .= " $me" if $me ne '';
    $whr .= $sp."WHERE $s"    if $cnd && ($s = $self->sql_where($cnd, \@wx));
    $whr .= $sp."GROUP BY $s" if ($s = $opt->{group_by}) && ($s = $self->sql_cols($s, \@wx));
    $whr .= $sp."HAVING $s"   if ($s = $opt->{having})   && ($s = $self->sql_where($s, \@wx));
    $ord  = $sp."ORDER BY $s" if ($s = $opt->{order_by}) && ($s = $self->sql_cols($s, \@ox));
    
    $self->resolve_ambiguous($sch, $me, \$whr, \$ord) if $ji;
    $self->interpolate_sql(\$cols, \@cx) if @cx;
    $self->interpolate_sql(\$whr,  \@wx) if @wx;
    $self->interpolate_sql(\$ord,  \@ox) if @ox;
    
    $src .= $whr;
    push @sx, @wx;
    
    if($mj && $rows){
        my $pk = $sch->primary_key || die $sch->_dmsg_(7);
        my $pks = join(', ', map{ "$me.$_" } @$pk);
        (my $us = "\nSELECT $pks FROM $t$src\nGROUP BY $pks") =~ s/\n/\n  /g;
        @s{qw/cnt sx/} = ("SELECT COUNT(*) FROM ($us\n) us", \@sx) if $wa;
        $us .= ' '.substr($ord, 1) if $ord;
        $self->sql_limit(\$us, $rows, $page);
        $s{sql} = "SELECT $cols FROM ($us\n) us JOIN $t ON ".
            join(' AND ', map{ "$me.$_ = us.$_" } @$pk).$src.$ord;
        $s{x} = [@cx, @sx, @ox, @sx, @ox];
    }else{
        @s{qw/cnt sx/} = ("SELECT COUNT(*) FROM $t$src", \@sx) if $wa;
        $s{sql} = "SELECT $cols${sp}FROM $t$src$ord";
        $self->sql_limit(\($s{sql}), $rows, $page) if $rows;
        $s{x} = [@cx, @sx, @ox];
    }
    $s{sql} .= $sp."FOR $s" if ($s = $opt->{for});
    \%s;
}

sub sql_cols {
    return $_[1] if !ref $_[1];
    my($self, $s, $x) = @_;
    join ', ', map{ ref $_ ? push(@$x, @{$_}[1 .. $#$_]) && $_->[0] : $_ } @$s;
}

sub sql_where {
    my($self, $w, $x, $wrap, $set) = @_;
    
    ($w = [map{
        $set || defined $w->{$_} ? ["$_ = ?", $w->{$_}] : ["$_ IS NULL"]
    } sort grep{ !/\s/ } keys %$w]) && ($wrap = 0) if UNIVERSAL::isa($w, 'HASH');
    
    if(!ref $w->[0]){
        push @$x, @{$w}[1 .. $#$w];
        return $w->[0];
    }
    
    my($s, $and) = ($wrap ? '(' : '');
    foreach(@$w){
        if(!$set && $_ eq '-or'){
            $s .= ' OR ';
            $and = 0;
        }else{
            $s .= $set ? ', ' : ' AND ' if $and;
            $s .= $self->sql_where($_, $x, 1, $set);
            $and = 1;
        }
    }
    $wrap ? $s.')' : $s;
}

sub typeof { '?' }

sub user { shift->master_dsn->[1] }

1;
