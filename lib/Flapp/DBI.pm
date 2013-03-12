package Flapp::DBI;
use Flapp qw/-b DBI -s -w/;
use constant dbh_pool => 'Flapp::DBI::dbh_pool';

sub dbh {
    my($self, $proj, $dbn) = (shift, shift, shift);
    ($proj->_global_->{dbh_pool}{$dbn} ||= $self->dbh_pool->new($proj, $dbn))->dbh(@_);
}

package Flapp::DBI::dbh_pool;

sub connect {
    my($self, $i) = @_;
    my $proj = $self->{project};
    my $cfg = $proj->config->DB->AUTOLOAD($self->{DBN})->dsn->[$i];
    my $dbh = DBI->connect(@{$cfg}[0 .. 2], {
        %{$cfg->[3] || {}},
        PrintError => 0,
        RaiseError => 0,
        RootClass => $proj->DBI,
        private_flapp_dbh => my $pfd = [$self => $i],
    }) || do{
        die $DBI::errstr if !$i;
        warn "Trying master dbh because slave($self->{DBN}:$i) connection failed: $DBI::errstr";
        $self->dbh(0)->clone;
    };
    $proj->_weaken_($pfd->[0]);
    $dbh->STORE(RaiseError => 1);
    if(my $org = $self->{DBHS}[$i]){
        #warn "DBH reconnected ($self->{DBN}:$i)";
        $org->swap_inner_handle($dbh);
        return $org;
    }
    $self->{DBHS}[$i] = $dbh;
}

sub dbh {
    my $self = shift;
    my $i = @_ ? shift : ($self->{idx} = ($self->{idx} + 1) % @{$self->{DBHS}});
    $self->{DBHS}[$i] ||= $self->connect($i);
}

sub finalize {
    my $self = shift;
    $self->_txl_flush if $self->{txl};
    $self->{auto_reconnect} = $self->{use_master} = 0;
    $self->{txl} = undef;
    $self;
}

sub new {
    my($class, $proj, $dbn) = @_;
    my $self = bless {
        DBHS           => [map{ undef }@{$proj->config->DB->$dbn->dsn}],
        DBN            => $dbn,
        auto_reconnect => 0,
        idx            => -1,
        project        => $proj,
        rbs            => undef,
        txl            => undef,
        use_master     => 0,
    }, $class;
    $self;
}

sub _txl_add {
    my($self, $i) = (shift, shift->FETCH('AutoCommit') ? 1 : 2);
    my $p = (my $txl = $self->{txl} || die)->{p} = shift;
    push @{$p->[$i]}, \("\t".$self->{project}->Util->ary2tsv(++$txl->{seq}.':', @_)."\n");
}

sub _txl_commit {
    @{$_->[2]} && push(@{$_->[1]}, splice @{$_->[2]}) for @{($_[0]->{txl} || die)->{ps}};
}

sub _txl_flush {
    my $self = shift;
    my($txl, $proj, $buf, $n) = ($self->{txl} || die, $self->{project});
    foreach my $p (@{$txl->{ps}}){
        $n++ if @{$p->[2]}; #uncommitted
        next if !@{$p->[1]}; #committed
        $buf .= $proj->Util->ary2tsv($p->[0])."\n";
        $buf .= $$_ for splice @{$p->[1]};
    }
    warn "Found $n uncommitted txn" if $n;
    return !1 if !$buf;
    my $lgr = $proj->logger($txl->{log} || 'txn');
    local $Flapp::Logger::DEBUG if $Flapp::Logger::DEBUG;
    $lgr->print($lgr->now->hms."\t$txl->{head}\n$buf\n");
}

sub _txl_new { {head => $_[1], log => $_[2], p => undef, ph => {}, ps => [], seq => 0} }

sub _txl_prepare {
    my $txl = $_[0]->{txl} || die;
    $txl->{ph}{$_[1]} ||= ($txl->{ps}[@{$txl->{ps}}] = [$_[1], [], []]);
}

sub _txl_rollback { undef @{$_->[2]} for @{($_[0]->{txl} || die)->{ps}} }

package Flapp::DBI::db;
@Flapp::DBI::db::ISA = qw/DBI::db/;

sub auto_reconnect {
    my $dbh = shift;
    die 'No arguments' if !@_;
    $dbh->FETCH('private_flapp_dbh')->[0]{auto_reconnect} = $_[0] ? 1 : 0;
    $dbh;
}

sub auto_reconnect_do {
    my($dbh, $cb, $rescue) = (shift, shift, shift);
    my $pfd = $dbh->FETCH('private_flapp_dbh'); # [dbh_pool => dbh_id]
    $pfd->[0]{auto_reconnect} = 0; #try once
    my($wa, $warn, $die, @r, $r) = (wantarray, '');
    eval{
        local $::SIG{__WARN__} = sub{ $warn .= $_[0] };
        $wa ? (@r = $cb->(@_)) : ($r = $cb->(@_))
    };
    if(($die = $@) && !$dbh->ping){
        $pfd->[0]->connect($pfd->[1]);
        $rescue->() if $rescue;
        return $cb->(@_);
    }
    warn $warn if $warn;
    die $die if $die;
    $wa ? @r : $r;
}

sub debug {
    my($dbh, $method, $sql) = (shift, shift, shift || '', shift);
    $sql =~ s/\?/$dbh->quote(shift(@_))/eg;
    $sql =~ s/^[\t\n\r ]+//;
    $sql =~ s/[\t\n\r ]+\z//;
    $sql = qq{"$sql"} if $sql;
    my $pfd = $dbh->FETCH('private_flapp_dbh'); # [dbh_pool => dbh_id]
    $pfd->[0]{project}->debug_with_trace("\$($pfd->[0]{DBN}:$pfd->[1])->$method($sql)",
        qr/^ at .+\(Flapp\/(DBI\.pm|Schema.+) [0-9]+\)\n/);
}

sub flush_txn_log { $_[0]->FETCH('private_flapp_dbh')->[0]->_txl_flush }

sub master {
    my $dbh = shift;
    my $pfd = $dbh->FETCH('private_flapp_dbh'); # [dbh_pool => dbh_id]
    ($pfd->[1] ? $pfd->[0]->dbh(0) : $dbh);
}

sub no_txn_do {
    my($dbh, $cb) = (shift, shift);
    local $dbh->FETCH('private_flapp_dbh')->[2] = 1;
    $cb->(@_);
}

sub no_txn_log_do {
    my($dbh, $cb) = (shift, shift);
    local $dbh->FETCH('private_flapp_dbh')->[0]{txl};
    $cb->(@_);
}

sub rbs { $_[0]->FETCH('private_flapp_dbh')->[0]{rbs} }

sub txn_do {
    my($dbh, $cb) = (shift, shift);
    return $cb->(@_) if $dbh->master->FETCH('BegunWork');
    $dbh->begin_work;
    my $r = eval{ $cb->(@_) };
    return $dbh->commit && $r if !(my $msg = $@);
    $dbh->rollback;
    die $msg;
}

sub txn_log {
    my $dbh = shift;
    die 'No arguments' if !@_;
    my $pool = $dbh->FETCH('private_flapp_dbh')->[0];
    $pool->_txl_flush if $pool->{txl};
    $pool->{txl} = $_[0] ? $pool->_txl_new(@_) : undef;
    $dbh;
}

sub use_master {
    my $dbh = shift;
    $dbh->FETCH('private_flapp_dbh')->[0]{use_master} = 1;
    $dbh;
}

sub _define_method {
    my($self, $method, $cb, $is_txn, $prepare) = @_;
    my $code = sub{
        my $dbh = shift;
        my $pfd = $dbh->FETCH('private_flapp_dbh'); # [dbh_pool => dbh_id]
        return $pfd->[0]->dbh(0)->$method(@_) if $pfd->[1] && !$pfd->[2] && (
            $pfd->[0]{use_master} || (
                $is_txn
             || $_[0] !~ /^[\t\n\r ]*select/i #not select
             || !$pfd->[0]->dbh(0)->FETCH('AutoCommit')
             && $_[0] =~ /[\t\n\r ]for[\t\n\r ]+update\b/i
            ) && $dbh->use_master
        );
        
        return $cb->($dbh, $pfd, @_) if $prepare || !$pfd->[0]{auto_reconnect};
        $dbh->auto_reconnect_do(sub{ $cb->($dbh, $pfd, @_) }, undef, @_);
    };
    no strict 'refs';
    *$method = $code;
}

__PACKAGE__->_define_method('begin_work', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('begin_work') if $::ENV{FLAPP_DEBUG};
    my $rc = $dbh->SUPER::begin_work(@_);
    $pfd->[0]{rbs} = [[], {}];
    $rc;
}, 1);

__PACKAGE__->_define_method('commit', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('commit') if $::ENV{FLAPP_DEBUG};
    my $rc = $dbh->SUPER::commit(@_);
    $pfd->[0]->_txl_commit if $pfd->[0]{txl};
    $pfd->[0]{rbs} = undef;
    $rc;
}, 1);

__PACKAGE__->_define_method('do', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('do', @_) if $::ENV{FLAPP_DEBUG};
    my $rv = $dbh->SUPER::do(@_);
    $pfd->[0]->_txl_add($dbh, $pfd->[0]->_txl_prepare($_[0]), @_[2 .. $#_]) if $pfd->[0]{txl};
    $rv;
}, 1);

foreach(qw/prepare prepare_cached/){
    my $super = "SUPER::$_";
    __PACKAGE__->_define_method($_, sub{
        my($dbh, $pfd) = (shift, shift);
        my $sth = $dbh->$super(@_);
        $sth->STORE(private_flapp_txl_p => $pfd->[0]->_txl_prepare($_[0]))
            if $pfd->[0]{txl} && $_[0] !~ /^[\t\n\r ]*select/i;
        $sth;
    }, undef, 1);
}

__PACKAGE__->_define_method('rollback', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('rollback') if $::ENV{FLAPP_DEBUG};
    my $rc = $dbh->SUPER::rollback(@_);
    $pfd->[0]->_txl_rollback if $pfd->[0]{txl};
    shift(@$_)->on_rollback(@$_) for @{$pfd->[0]{rbs}[0]};
    $pfd->[0]{rbs} = undef;
    $rc;
}, 1);

require Encode if $Flapp::UTF8;
my $MB = qr/[^\x00-\x7F]/;
my $UTF8_ON = sub{ Encode::_utf8_on(my $s = $_[0]); $s };

__PACKAGE__->_define_method('selectall_arrayref', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('selectall_arrayref', @_) if $::ENV{FLAPP_DEBUG};
    my $rs = $dbh->SUPER::selectall_arrayref(@_);
    return $rs if !$Flapp::UTF8 || !@$rs;
    
    if(ref $rs->[0] eq 'ARRAY'){
        foreach my $r (@$rs){
            Encode::_utf8_on($_) for @$r;
        }
    }elsif($Flapp::UTF8 > 1 && (my @mb = grep{ /$MB/ } keys %{$rs->[0]})){
        foreach my $r (@$rs){
            $r->{$UTF8_ON->($_)} = delete $r->{$_} for @mb;
        }
    }
    $rs;
});

__PACKAGE__->_define_method('selectall_hashref', sub{
    my($dbh, $pfd) = (shift, shift);
    my $rs = $dbh->SUPER::selectall_hashref(@_);
    return $rs if !$Flapp::UTF8 || !%$rs;
    
    my %mb;
    Flapp->Util->recursive_do({
        hash_ref => sub{
            my($next, $ref) = @_;
            ($mb{$_} ||= /$MB/ ? 2 : 1) == 2
             && ($ref->{$UTF8_ON->($_)} = delete $ref->{$_}) for keys %$ref;
            $next->($ref);
        },
        sort_keys => 0,
    }, $rs) if $Flapp::UTF8 > 1;
    $rs;
});

__PACKAGE__->_define_method('selectcol_arrayref', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->SUPER::selectcol_arrayref(@_);
});

__PACKAGE__->_define_method('selectrow_array', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('selectrow_array', @_) if $::ENV{FLAPP_DEBUG};
    return $dbh->SUPER::selectrow_array(@_) if !$Flapp::UTF8;
    map{ $UTF8_ON->($_) } $dbh->SUPER::selectrow_array(@_);
});

__PACKAGE__->_define_method('selectrow_arrayref', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->debug('selectrow_arrayref', @_) if $::ENV{FLAPP_DEBUG};
    my $r = $dbh->SUPER::selectrow_arrayref(@_) || return undef;
    return $r if !$Flapp::UTF8;
    Encode::_utf8_on($_) for @$r;
    $r;
});

__PACKAGE__->_define_method('selectrow_hashref', sub{
    my($dbh, $pfd) = (shift, shift);
    $dbh->SUPER::selectrow_hashref(@_);
});

package Flapp::DBI::st;
@Flapp::DBI::st::ISA = qw/DBI::st/;

sub execute {
    my $sth = shift;
    my $dbh = $sth->FETCH('Database');
    $dbh->debug('execute', $sth->FETCH('Statement'), undef, @_) if $::ENV{FLAPP_DEBUG};
    my $pool = $dbh->FETCH('private_flapp_dbh')->[0];
    my $rv = !$pool->{auto_reconnect} ? $sth->SUPER::execute(@_) : do{
        $dbh->auto_reconnect_do(
            sub{ $sth->SUPER::execute(@_) },
            sub{ $sth->swap_inner_handle($dbh->prepare($sth->FETCH('Statement')), 1) },
            @_,
        );
    };
    my $p = $sth->FETCH('private_flapp_txl_p');
    $pool->_txl_add($dbh, $p, @_) if $p;
    $rv;
}

if($Flapp::UTF8){
    *fetch = sub{
        my $r = shift->SUPER::fetch(@_) || return undef;
        return $r if !$Flapp::UTF8;
        Encode::_utf8_on($_) for @$r;
        $r;
    };
    *fetchrow_arrayref = sub{
        my $r = shift->SUPER::fetchrow_arrayref(@_) || return undef;
        return $r if !$Flapp::UTF8;
        Encode::_utf8_on($_) for @$r;
        $r;
    };
    *fetchrow_hashref = sub{
        my $sth = shift;
        my $r = $sth->SUPER::fetchrow_hashref(@_) || return undef;
        return $r if !$Flapp::UTF8;
        my $mb = $sth->FETCH('private_flapp_name_mb');
        $sth->STORE(private_flapp_name_mb =>
            $mb = [grep{ /$MB/ } @{$sth->FETCH('NAME_lc')}]) if !$mb;
        $r->{$UTF8_ON->($_)} = delete $r->{$_} for @$mb;
        $r;
    } if $Flapp::UTF8 > 1;
}

1;
