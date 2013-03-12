package Flapp::Schema;
use Flapp qw/-m -s -w/;
use constant LOCK_VERSION => 'lock_version';
use constant OPTIONS_ON_DELETE => {};
use constant OPTIONS_ON_SAVE => {
    -f => 0,     #force
    -l => undef, #lock
    -t => 1,     #timestamp
};
use constant OPTIONS_ON_SET_COLUMNS => {
    -o => undef, #only
    -x => sub{ [map{ $_->{-a} ? $_->{name} : () } @{shift->column_infos}] }, #except
};
use constant SET_CURRENT_TIME_ON_NEW => [qw/created_at updated_at/];
use constant SET_CURRENT_TIME_ON_UPDATE => [qw/updated_at/];

sub cd2str {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = (shift, shift);
    $row->Util->cd2str($row->get_column($cn), $row->column_enum($cn), @_);
}

sub _deflate_ {
    return undef if !defined $_[2];
    my($row, $ci) = @_;
    my $m = 'deflate_'.$ci->{-i};
    $row->storage->$m($_[2], $row, $ci->{name});
}

sub delete {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    my $opt = $row->_merge_options_($row->OPTIONS_ON_DELETE, @_);
    my($org, $txn, $cih) = ($row->{-org}, $row->{-txn} ||= {}, $row->column_info);
    
    my %_txn;
    foreach my $cn (@{$row->columns}){
        if(exists $txn->{$cn}){
            $_txn{$cn} = $txn->{$cn};
        }elsif(defined $org->{$cn}){
            my $ci = $cih->{$cn} || die $cn;
            $_txn{$cn} = $ci->{-i} ? $row->_inflate_($ci, $org->{$cn}) : $org->{$cn};
        }
    }
    $opt->{where} = $row->primary_key || die $row->_dmsg_(7);
    $row->_storage_do_(delete => undef, \%_txn, $opt);
}

sub discard_changes {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    die "Can't discard_changes of new row" if !$row->{-org};
    delete $row->{-txn};
    $row;
}

sub errors {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    $row->{errors} ||= $row->project->Errors->new->label({
        map{ exists $_->{-l} ? ($_->{name} => $_->{-l}) : () }
        @{$row->column_infos}, @{$row->relation_infos}
    });
}

sub get_column {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = @_;
    my($h, $ci);
    
    return $h->{$cn} if ($h = $row->{-txn}) && exists $h->{$cn};
    die $row->_dmsg_(6, $cn) if ($h = $row->{-org}) && !exists $h->{$cn};
    return $h->{$cn} if !defined $h->{$cn} || !($ci = $row->column_info->{$cn}) || !$ci->{-i};
    $row->{-txn}{$cn} = $row->_inflate_($ci, $h->{$cn});
}

sub get_columns {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    my %h;
    $row->has_column_loaded($_) && ($h{$_} = $row->get_column($_)) for @{$row->columns};
    if(my $rel = shift){
        foreach my $k (keys %$rel){
            my $r = $row->get_related($k);
            $h{$k} = !$r ? undef : ref $r eq 'ARRAY' ? [map{ $_->get_columns($rel->{$k}) } @$r] :
                $r->get_columns($rel->{$k});
        }
    }
    
    \%h;
}
*TO_JSON = \&get_columns;

sub get_org_column {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = @_;
    my $ci = $row->column_info($cn);
    my $h = $row->{-org};
    die $row->_dmsg_(6, $cn) if !$h || !exists $h->{$cn};
    $ci->{-i} ? $row->_inflate_($ci, $h->{$cn}) : $h->{$cn};
}

sub has_column_loaded {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = @_;
    my $h;
    ($h = $row->{-org}) && exists $h->{$cn} || ($h = $row->{-txn}) && exists $h->{$cn} || !1;
}

sub _inflate_ {
    return undef if !defined $_[2];
    my($row, $ci) = @_;
    my $m = 'inflate_'.$ci->{-i};
    $row->storage->$m($_[2], $row, $ci->{name});
}

sub insert {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    my $opt = $row->_merge_options_($row->OPTIONS_ON_SAVE, @_);
    my($org, $txn, $cih) = ($row->{-org}, $row->{-txn}, $row->column_info);
    
    my(%_org, %_txn);
    foreach my $cn (@{$row->columns}){
        if(exists $txn->{$cn}){
            my $ci = $cih->{$cn} || die $cn;
            $_org{$cn} = $ci->{-i} ? $row->_deflate_($ci, $_txn{$cn} = $txn->{$cn}) : $txn->{$cn};
        }else{
            next if !defined($_org{$cn} = $org->{$cn});
        }
        push @{$opt->{ins} ||= []}, $cn;
    }
    
    $row->_storage_do_(insert => \%_org, \%_txn, $opt);
}

sub in_storage { ref $_[0] ? !!$_[0]->{-org} : die $_[0]->_dmsg_(2) }

sub is_changed {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    my $txn = $row->{-txn} || return !1;
    my $cih = $row->column_info;
    my @i;
    $cih->{$_}{-i} ? push(@i, $_) : $row->is_column_changed($_) && return 1 for keys %$txn;
    $row->is_column_changed($_) && return 1 for @i;
    !1;
}

sub _is_changed_ {
    my $d1 = defined $_[1];
    ($d1 xor defined $_[2]) || $d1 && $_[2] ne $_[1];
}

sub is_column_changed {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = @_;
    my $ci = $row->column_info($cn);
    my($org, $txn);
    ($org = $row->{-org}) && exists($org->{$cn}) || return 1;
    ($txn = $row->{-txn}) && exists($txn->{$cn}) || return !1;
    $row->_is_changed_($org->{$cn}, $ci->{-i} ? $row->_deflate_($ci, $txn->{$cn}) : $txn->{$cn});
};

sub is_valid {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    $row->errors->clear;
    $row->validate(@_)->errors->is_empty;
}

sub on_rollback { shift->_storage_do_(undef, @_) }

sub _ox_columns_ {
    my($self, $opt) = @_;
    return $opt->{-o} if $opt->{-o};
    return $self->columns if !$opt->{-x};
    my %x = map{ $_ => 1 } @{$opt->{-x}};
    [grep{ !$x{$_} } @{$self->columns}];
}

sub _rowid_ {
    my $row = shift;
    join "\0", @{$row->{-org} || die}{@{$row->primary_key || die $row->_dmsg_(7)}};
}

sub save {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    $_[0]->{-org} ? shift->update(@_) : shift->insert(@_);
}

sub set_column {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = @_;
    my $ci = $row->column_info($cn);
    my $fk = $Flapp::Schema::SYNC_FK && $ci->{fk} && (my $d = $row->_data_)->{-vfk};
    $fk &&= $fk->{$cn} && $row->_is_changed_($row->get_column($cn), $_[2]);
    
    $row->{-txn}{$cn} = ref $_[2] ? (
        $ci->{-i} ? $_[2] : die qq{Can't set non-scalar value $_[2] for "$cn"}
    ) : (
        $ci->{-i} ? $row->_inflate_($ci, $_[2]) :
        $cn eq $row->LOCK_VERSION && !$row->in_storage ? ($_[2] || 1) : $_[2]
    );
    
    $row->_vfk_change_({$cn => $row->_vfk_($_[2])}, 1, 0, $d) if $fk;
    $row;
}

sub set_columns {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $h) = (shift, shift);
    my $opt = $row->_merge_options_($row->OPTIONS_ON_SET_COLUMNS, @_);
    exists $h->{$_} && $row->set_column($_, $h->{$_}) for @{$row->_ox_columns_($opt)};
    $row;
}

sub _storage_do_ {
    my($row, $do, $_org, $_txn, $opt) = @_;
    my($org, $txn, $sc) = ($row->{-org}, $row->{-txn}, $row->_schema_cache_);
    my $k1 = $sc && $org && $row->_rowid_;
    
    if($do){
        my($sto, $rbs) = ($row->storage);
        $sto->$do($row, $_org, $_txn, $opt);
        unshift @{$rbs->[0]}, [$row, $org, $txn] if ($rbs = $sto->rbs) && !$rbs->[1]{int $row}++;
    }
    
    $_org           ? ($row->{-org} = $_org) : delete $row->{-org};
    $_txn && %$_txn ? ($row->{-txn} = $_txn) : delete $row->{-txn};
    
    return $row if !$sc;
    if(!$org){ #insert
        $sc->{$row->_rowid_} = $row;
    }elsif(defined $k1 && exists $sc->{$k1}){
        if(!$_org){ #delete
            $sc->{$k1} = undef;
        }elsif((my $k2 = $row->_rowid_) ne $k1){ #update
            $sc->{$k1} = undef;
            $sc->{$k2} = $row;
        }
    }
    
    $row;
}

sub update {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    my $opt = $row->_merge_options_($row->OPTIONS_ON_SAVE, @_);
    my($org, $txn, $cih) = ($row->{-org}, $row->{-txn}, $row->column_info);
    my $f = $opt->{-f};
    $f = {map{ $_ => 1 } @$f} if $f && ref $f eq 'ARRAY';
    
    my(%_org, %_txn);
    foreach my $cn (@{$row->columns}){
        if(exists $txn->{$cn}){
            my $ci = $cih->{$cn} || die $cn;
            $_org{$cn} = $ci->{-i} ? $row->_deflate_($ci, $_txn{$cn} = $txn->{$cn}) : $txn->{$cn};
            $opt->{set}{$cn} = 1 if $f && (ref $f ne 'HASH' || $f->{$cn})
             || !exists $org->{$cn} || $row->_is_changed_($_org{$cn}, $org->{$cn});
        }elsif(exists $org->{$cn}){
            $_org{$cn} = $org->{$cn};
        }
    }
    return $row if !$opt->{set};
    
    if($opt->{-t}){
        my($ci, $now);
        foreach my $cn (@{$row->SET_CURRENT_TIME_ON_UPDATE}){
            ($ci = $cih->{$cn}) && $ci->{-i} || next;
            $_org{$cn} = $row->_deflate_($ci, $_txn{$cn} = ($now ||= $row->project->now)->clone);
            $opt->{set}{$cn} = 1;
        }
    }
    
    my $w = $opt->{where} = $row->primary_key || die $row->_dmsg_(7);
    my $lv = $row->LOCK_VERSION;
    if($lv && $cih->{$lv} && (defined $opt->{-l} ? $opt->{-l} : exists $txn->{$lv})){
        $opt->{where} = [@$w, $lv];
        $_org{$lv} = ($org->{$lv} || 0) % 127 + 1;
        $opt->{set}{$lv} = 1;
    }
    
    $row->_storage_do_(update => \%_org, \%_txn, $opt);
}

sub validate {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $row = shift;
    $row->validate_column($_) for @{$row->columns};
    $row;
}

sub validate_column {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $cn) = (shift, shift);
    my $ci = $row->column_info($cn);
    my(@v, @e);
    
    if(!@_ && ($ci->{-a} || (my $ri = $ci->{fk} && $ci->{fk}{-a}))
     && !defined($v[0] = $row->get_column($cn))){
        my $r = $ri ? $row->_related_on_($ri, $cn) : $row;
        return 1 if $r && !$r->in_storage;
    }
    
    my $v = @_ ? \@_ : $ci->{-v};
    $row->errors->add($cn, @e)
        if $v && (@e = $row->project->validate(@v ? \$v[0] : $row->get_column($cn), @$v));
    $row->errors->add('', @e = (199))
        if !@_ && $cn eq $row->LOCK_VERSION && $row->in_storage && $row->is_column_changed($cn);
    
    !@e;
}

1;
