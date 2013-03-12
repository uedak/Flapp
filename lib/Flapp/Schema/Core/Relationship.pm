package Flapp::Schema;
use Flapp qw/-m -s -w/;
use constant MULTIPLICITY => {
    '1' => {},
    '?' => {outer => 1},
    '+' => {multi => 1},
    '*' => {multi => 1, outer => 1},
};
use constant OPTIONS_ON_SAVE_RELATED => {
    -d => 0, #direct
};
use constant RELATION_OPTIONS => {
    -l             => 1,
    -m             => 1,
    -no_cache      => 1,
    -no_constraint => 1,
    -on            => 1,
    -order_by      => 1,
};

use Scalar::Util;
my $ISW = \&Scalar::Util::isweak;
my $WKN = \&Scalar::Util::weaken;
our($SYNC_FK, $VFK, $VFK_SEQ) = (1, 0, 0);

our $R0;
sub DESTROY {
    my $row = shift;
    return $R0->{$row->_r2x_} = $row if $R0;
    my $d = $row->_data_;
    if($d->{-rel} && !$ISW->($d->{-rel})){
        my $x = $row->_r2x_;
        my $r = [@{$d->{-rel}}];
        $WKN->($d->{-rel});
        return $r->[0]{$x} = $row if $d->{-rel}; #strengthen
        
        local $R0 = $r->[0];
        my %a;
        foreach(keys %$R0){
            next if $_ eq $x;
            $WKN->($R0->{$_});
            $a{$_} = 1 if $ISW->($R0->{$_});
        }
        if(%a){
            $a{$_->_r2x_} ? ($_->_data_->{-rel} = $r) :
                $WKN->($_->_data_->{-rel} = $r) for values %$R0;
            return $r->[0]{$x} = $row;
        }
    }
    $VFK_SEQ = 0 if $VFK && $d->{-vfk} && !--$VFK;
    $row->SUPER::DESTROY(@_);
}

sub _add_relation_ {
    my($sch, $t, $m, $rn, $sn, $opt) = @_;
    die $sch->_dmsg_(4, $rn) if $sch->can($rn);
    my $rsch = $sch->SCHEMA_BASE->$sn;
    $sch->RELATION_OPTIONS->{$_} || die qq{Invalid option "$_" for $sch->$rn} for keys %$opt;
    
    my $ri = {-m => $m, name => $rn, schema => $rsch, type => $t, %$opt};
    $ri->{_multi} = 1 if ($m = $sch->_multiplicity_($ri->{-m}, $rn)->{multi});
    
    my $on = $opt->{-on} || $sch->Util->class2path($sch->_schema_name_).'_id';
    $on = $sch->_join_on_pk_($rn, "$on = me.%s") if !ref $on;
    my $w = $sch->storage->sql_where($on, []) || die $sch->_dmsg_(8, $rn);
    $w = $1 while $w =~ /^[\t\n\r ]*\((.*)\)[\t\n\r ]*\z/s;
    my(%on, %rr, @ci);
    foreach(split /[\t\n\r ]+AND[\t\n\r ]+/i, $w, -1){
        $_ = $1 while /^[\t\n\r ]*\((.*)\)[\t\n\r ]*\z/s;
        $on = /^[\t\n\r ]*(\w+)\.(\w+)[\t\n\r ]*=[\t\n\r ]*(\w+)\.(\w+)[\t\n\r ]*\z/ && (
            ($1 eq $rn && $3 eq 'me' && [$2, $4] || $1 eq 'me' && $3 eq $rn && [$4, $2])
        ) || die qq{Can't parse "$_" for $sch->$rn};
        push @ci, [$rsch->column_info($on->[0]), $sch->column_info($on->[1])];
        $on{$on->[1]} = $on;
        $rr{$on->[0]} = 1;
    }
    $ri->{on} = [map{ $on{$_} ? $on{$_} : () } @{$sch->columns}];
    my @rr = grep{ $rr{$_} } @{$rsch->columns};
    $rsch->_global_->{reverse_relation}{join(',', @rr)} ||= {schema => $rsch,
        on => [map{ [$_, $_] } @rr], $m ? (_multi => 1) : ()} if !$ri->{-no_cache};
    my $pk = $rsch->primary_key;
    $ri->{pk} = 1 if $pk && @rr == @$pk && join(',', sort @rr) eq join(',', sort @$pk);
    
    foreach my $ci (@ci){
        die '?' if $ci->[0]{fk} && $ci->[1]{fk} && ($ci->[0]{fk} != $ci->[1]{fk});
        my $fk = $ci->[0]{fk} = $ci->[1]{fk} = $ci->[0]{fk} || $ci->[1]{fk} || {};
        $fk->{-a} = {schema => $rsch, on => [[$ci->[0]{name}, undef]]} if $ci->[0]{-a};
        $fk->{-a} = {schema => $sch,  on => [[$ci->[1]{name}, undef]]} if $ci->[1]{-a};
    }
    
    my $g = $sch->_global_;
    push @{$g->{relations} ||= []}, $rn;
    $g->{relation_info}{$rn} = $ri;
    $sch->_define_method_($rn, sub{
        @_ > 1 ? shift->set_related($rn, @_) : shift->get_related($rn)
    });
    $sch;
}

sub belongs_to {
    die $_[0]->_dmsg_(1) if ref $_[0];
    my($sch, $rn, $sn, $opt) = @_;
    my $on = $opt->{-on} || $rn.'_id';
    $on = $sch->_join_on_pk_($rn, "%s = me.$on", $sn) if !ref $on;
    $sch->_add_relation_(belongs_to => '?', $rn, $sn, {%$opt, -on => $on});
}

sub find_or_new_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $rn) = @_;
    my $ri = $row->relation_info($rn);
    die qq{Can't find_or_new_related multiple relationship "$rn"} if $ri->{_multi};
    $row->get_related($rn) || $row->set_related($rn, {})->get_related($rn);
}

sub get_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $rn, $opt) = @_;
    my $d = $row->_data_;
    return $d->{-join}{$rn} if $d->{-join} && exists $d->{-join}{$rn};
    my $ri = $row->relation_info($rn);
    my(@rs, $_r1);
    if((my $dr = $d->{-rel}) && (my $_r = $row->_related_($ri, $d))){
        @rs = map{ $dr->[0]{$_} || die $_ } @{$_r->[0]};
        $_r1 = $_r->[1] || return $ri->{_multi} ? \@rs : $rs[0];
    }
    
    my $w = $row->_join_conditions_($ri) || return $ri->{_multi} ? \@rs : $rs[0];
    my $rs;
    if($ri->{_multi}){ #has_many
        $opt = {order_by => $ri->{-order_by}, %{$opt || {}}} if $ri->{-order_by};
        $rs = $ri->{schema}->search($w, $opt);
        my %i = map{ $_->in_storage ? ($_->_rowid_ => $_)  : () } @rs;
        my($i, $r, %r);
        $rs = [map{
            ($r = $i{$i = $_->_rowid_}) && ($r{int $r} = $r) || ($_r1 && $_r1->{$i} ? () : $_)
        } @$rs] if %i || $_r1 && %$_r1;
        $rs = %r ? [@$rs, (grep{ !$r{int $_} } @rs)] : [@$rs, @rs] if @rs;
    }else{
        $rs = $ri->{pk} ? $ri->{schema}->find([map{ $_->[1] } @$w], $opt) :
            $ri->{schema}->search($w, $opt)->[0];
    }
    local $SYNC_FK, $row->set_related($rn, $rs) if !$ri->{-no_cache};
    $rs;
}

sub has_many { ref $_[0] ? die shift->_dmsg_(1) : shift->_add_relation_(has_many => '*', @_) }

sub has_one { ref $_[0] ? die shift->_dmsg_(1) : shift->_add_relation_(has_one => 1, @_) }

sub has_relation_loaded {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $_r = $_[0]->_related_($_[0]->relation_info($_[1]));
    $_r && !$_r->[1];
}

sub _join_conditions_ {
    my($r, $ri) = @_;
    my($k, @w);
    defined($k = $r->get_column($_->[1])) ? push @w, ["$_->[0] = ?", $k] : return for @{$ri->{on}};
    \@w;
}

sub _join_on_pk_ {
    my($sch, $rn, $f, $sn) = @_;
    my $s = $sn ? $sch->SCHEMA_BASE->$sn : $sch;
    my $pk = $s->primary_key;
    die $sch->_dmsg_(8, $rn).": No single-column primary_key on $s" if !$pk || @$pk != 1;
    [$rn.'.'.sprintf($f, $pk->[0])];
}

sub many_to_many {
    my($sch, $rn, $rn2, $rn3) = @_;
    my($ri2, $ri3, $on);
    
    $sch->_define_method_($rn, sub{
        die $_[0]->_dmsg_(2) if !ref $_[0];
        my $row = shift;
        die qq{Many_to_many relationship "$rn" is readonly} if @_;
        $ri2 ||= $sch->relation_info($rn2);
        if(!$ri3){
            $ri3 = $ri2->{schema}->relation_info($rn3);
            die 'Composite foreign key is not supported in many_to_many' if @{$ri3->{on}} > 1;
            $on = $ri3->{on}[0] || die '?';
        }
        
        if($row->_related_($ri2)){
            my %i2r;
            foreach(@{$row->get_related($rn2)}){
                !$_->_related_($ri3) && defined(my $i = $_->get_column($on->[1])) || next;
                die qq{Duplicate foreign key "$i" on column "$on->[1]"} if $i2r{$i};
                $i2r{$i} = $_;
            }
            if(%i2r){
                my $rs = $ri3->{schema}->search(["$on->[0] IN (?)", [keys %i2r]]);
                (delete $i2r{$_->get_column($on->[0])})->_relate_($ri3, $_, 1) for @$rs;
                $_->_set_related_($ri3, []) for values %i2r;
            }
        }else{
            $row->get_related($rn2, {select => "me.*, $rn3.*", join => {$rn3 => {}}});
        }
        my $r;
        [map{ ($r = $_->get_related($rn3)) ? $r : () } @{$row->get_related($rn2)}];
    });
}

sub might_have { ref $_[0] ? die shift->_dmsg_(1) : shift->_add_relation_(might_have => '?', @_) }

sub _multiplicity_ {
    my $self = shift;
    die qq{No multiplicity(-m) for $self->$_[1]} if !$_[0];
    $self->MULTIPLICITY->{$_[0]} || die qq{Invalid multiplicity(-m) "$_[0]" for $self->$_[1]};
}

sub _r2x_ { substr $_[0], rindex($_[0], '(') + 3, -1 };

sub _relate_ {
    my($row, $ri, $r, $direct) = @_;
    my($r1, $r2, $i, $j) = $ri->{type} eq 'belongs_to' ? ($r, $row, 1, 0) : ($row, $r, 0, 1);
    my($d1, $d2, $x1, $x2) = ($r1->_data_, $r2->_data_, $r1->_r2x_, $r2->_r2x_);
    
    my $d1r = $d1->{-rel} ||= $d2->{-rel} || [{}, {}];
    my $r0 = $d1r->[0];
    $WKN->($r0->{$x1} = $r1) if !$r0->{$x1};
    if((my $d2r = $d2->{-rel} ||= $d1r) != $d1r){ #merge
        my $r02 = $d2r->[0];
        $WKN->($r02->{$x2} = $r2) if !$r02->{$x2};
        foreach(keys %$r02){
            my $r = $r02->{$_};
            my $d = $r->_data_;
            $ISW->($d->{-rel}) ? $WKN->($d->{-rel} = $d1r) : ($d->{-rel} = $d1r);
            $ISW->($r02->{$_}) ? $WKN->($r0->{$_} = $r) : ($r0->{$_} = $r) if !$r0->{$_};
        }
        foreach my $k (keys %{$d2r->[1]}){
            my($t1, $t2) = ($d1r->[1]{$k} ||= {}, $d2r->[1]{$k});
            $t1->{$_} ||= $t2->{$_} for keys %$t2;
        }
    }elsif(!$r0->{$x2}){
        $WKN->($r0->{$x2} = $r2);
    }
    
    $r1->_relate_vfk_($ri, $r2, $direct, $i, $j, $x1, $x2, $d1, $d2);
}

sub _relate_vfk_ {
    my($r1, $ri, $r2, $direct, $i, $j, $x1, $x2, $d1, $d2) = @_;
    $d2 ||= $r2->_data_;
    
    my($vfk1, $vfk2, %ch1, %ch2) = ($d1->{-vfk} ||= ++$VFK && {}, $d2->{-vfk} ||= ++$VFK && {});
    foreach(@{$ri->{on}}){
        my @fk;
        my $k1 = $vfk1->{$_->[$j]} ||= ($ch1{$_->[$j]} =
            ($vfk2->{$_->[$i]} || $r1->_vfk_($fk[0] = $r1->get_column($_->[$j]))));
        $ch2{$_->[$i]} = $k1 if ($vfk2->{$_->[$i]} || '') ne $k1;
        
        next if $direct || !$SYNC_FK;
        local $SYNC_FK, $r2->set_column($_->[$i], @fk ? $fk[0] : $r1->get_column($_->[$j]));
    }
    
    $r1->_vfk_change_(\%ch1, 0, $direct, $d1, $x1) if %ch1;
    $r2->_vfk_change_(\%ch2, 1, $direct, $d2, $x2) if %ch2;
}

sub _related_ {
    my($row, $ri, $d, $ch) = @_;
    $d ||= $row->_data_;
    my $vfk = $d->{-vfk} || return;
    my $q = join '&', map{
        $ch = undef if $ch && exists $ch->{$_->[1]};
        "$_->[0]=".($vfk->{$_->[1]} || return)
    } @{$ri->{on}};
    return if $ch;
    my $t = ($d->{-rel} || die)->[1]{$ri->{schema}->table} ||= {};
    wantarray ? ($t, $q) : $t->{$q};
}

sub _related_on_ {
    my($row, $ri) = @_;
    my $d = $row->_data_;
    my($dr, $_r, $x);
    ($dr = $d->{-rel}) && (local $ri->{on}[0][1] = $_[2]) && ($_r = $row->_related_($ri, $d))
     && ($x = $_r->[0][0]) && $dr->[0]{$x}
}

sub relations { shift->_global_->{relations} }

sub relation_info {
    my $ri = $_[0]->_global_->{relation_info};
    $ri = $ri->{$_[1]} || die $_[0]->_dmsg_(9, $_[1]) if @_ > 1;
    $ri;
}

sub relation_infos {
    my $g = shift->_global_;
    [@{$g->{relation_info}}{@{$g->{relations} || []}}];
}

sub relation_label {
    my $ri = shift->relation_info($_[0]);
    defined $ri->{-l} ? $ri->{-l} : die qq{No label(-l) defined on "$_[0]"};
}

sub save_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my $r = shift;
    $r->storage->save_related($r, shift, $r->_merge_options_($r->OPTIONS_ON_SAVE_RELATED, @_));
    $r;
}

sub search_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $rn, $where, $opt) = @_;
    my $ri = $row->relation_info($rn);
    $opt = {order_by => $ri->{-order_by}, %{$opt || {}}} if $ri->{-order_by};
    my $w = $row->_join_conditions_($ri) || return !$ri->{_multi} ? undef : !wantarray ? [] :
        ([], $row->project->Pager->new(0, $opt->{rows} || $row->DEFAULT_SEARCH_ROWS, $opt->{page}));
    
    ref $where eq 'ARRAY' ? @$where && push(@$w, ref $where->[0] ? $where : [$where]) :
    ref $where eq 'HASH'  ? %$where && push(@$w, $where) :
    die $where if defined $where;
    
    $ri->{_multi} ? $ri->{schema}->search($w, $opt) : $ri->{schema}->search($w, $opt)->[0];
}

sub set_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $rn, $r) = (shift, shift, shift);
    my $opt = $row->_merge_options_({-i => undef, -o => undef, -x => undef}, @_);
    my $ri = $row->relation_info($rn);
    my $rsch = $ri->{schema};
    my $o4s = ($opt->{-o} || $opt->{-x}) && {-o => $rsch->_ox_columns_($opt)};
    my(%org, $k, @xs, %xs);
    my $r2k = $opt->{-i} && sub{ join "\0", map{
        $k = ref $_[0] eq 'HASH' ? $_[0]->{$_} : $_[0]->get_column($_);
        defined $k && $k ne '' ? $k : return '';
    } @{$opt->{-i}} };
    if($r2k && (my $rs = $row->get_related($rn))){
        ($k = $r2k->($_)) ne '' && ($org{$k} = $_) for $ri->{_multi} ? @$rs : $rs;
    }
    foreach my $h ($ri->{_multi} ? @$r : $r ? $r : ()){
        $r = ref $h ne 'HASH' ? $h :
            %org && ($r = delete $org{$r2k->($h)}) ? $r->set_columns($h, $o4s) :
            $rsch->new($o4s ? {map{ exists $h->{$_} ? ($_ => $h->{$_}) : () } @{$o4s->{-o}}} : $h);
        my $x = $r->_r2x_;
        $xs{$x} ? die : push(@xs, $x) && ($xs{$x} = $r);
    }
    
    my $d = $row->_data_;
    if((my $dr = $d->{-rel}) && (my $_r = $row->_related_($ri, $d))){
        $row->_unrelate_($ri, $dr->[0]{$_}) for grep{ !delete $xs{$_} } @{$_r->[0]};
    }
    ($r = $xs{$_}) && $row->_relate_($ri, $r) for @xs;
    $row->_set_related_($ri, \@xs, $d);
    
    $row;
}

sub _set_related_ {
    my($row, $ri, $xs, $d) = @_;
    ($d ||= $row->_data_)->{-rel} ||= [{}, {}];
    my $vfk = $d->{-vfk} ||= ++$VFK && {};
    my %ch;
    $vfk->{$_->[1]} ||= ($ch{$_->[1]} = $row->_vfk_($row->get_column($_->[1]))) for @{$ri->{on}};
    $row->_vfk_change_(\%ch, 0, 1, $d) if %ch;
    (my($t, $q) = $row->_related_($ri, $d)) || die;
    $t->{$q} = [$xs];
}

sub _unrelate_ {
    my($row, $ri, $r) = @_;
    #my($r1, $r2, $i, $j) = $ri->{type} eq 'belongs_to' ? ($r, $row, 1, 0) : ($row, $r, 0, 1);
    #my($d1, $d2) = ($r1->_data_, $r2->_data_);
    #my($vfk1, $vfk2, %ch1, %ch2) = ($d1->{-vfk} || die, $d2->{-vfk} || die);
    my($r2, $i) = $ri->{type} eq 'belongs_to' ? ($row, 1) : ($r, 0);
    my %ch2;
    foreach(@{$ri->{on}}){
        #next if ($vfk1->{$_->[$j]} || '') ne ($vfk2->{$_->[$i]} || '');
        $ch2{$_->[$i]} = ++$VFK_SEQ;
        
        local $SYNC_FK, $r2->set_column($_->[$i], undef);
    }
    
    $r2->_vfk_change_(\%ch2, 1);
}

sub validate_related {
    die $_[0]->_dmsg_(2) if !ref $_[0];
    my($row, $rn) = (shift, shift);
    my $rs = $row->get_related($rn);
    my $e = $row->errors;
    $e->add($rn, $_->validate->errors) for ref $rs eq 'ARRAY' ? @$rs : $rs ? $rs : ();
    $row;
}

sub _vfk_ {
    !defined $_[1] ? ++$VFK_SEQ :
    ($_[1] !~ /[&\\]/ ? $_[1] : do{ (my $k = $_[1]) =~ s/([&\\])/\\$1/g; $k })."\0";
}

sub _vfk_change_ {
    my($row, $ch, $sync, $direct, $d, $x) = @_;
    $d ||= $row->_data_;
    $x ||= $row->_r2x_;
    
    my($dr0, @sync);
    if($sync){
        ($dr0, my $vfk) = (($d->{-rel} || die)->[0], $d->{-vfk} || die);
        foreach my $ri (values %{$row->_global_->{reverse_relation}}){
            my $_r = $row->_related_($ri, $d, $ch) || next;
            @{$_r->[0]} = grep{ $_ ne $x } @{$_r->[0]};
            $_r->[1]{$row->_rowid_} = 1 if $_r->[1] && $row->in_storage;
        }
        
        foreach my $ri (@{$row->relation_infos}){
            my $_r = $ri->{type} ne 'belongs_to' && $row->_related_($ri, $d, $ch) || next;
            push @sync, [$ri, $_] for @{$_r->[0]};
        }
        $vfk->{$_} = $ch->{$_} for keys %$ch;
    }
    
    foreach my $ri (values %{$row->_global_->{reverse_relation}}){
        (my($t, $q) = $row->_related_($ri, $d, $ch)) || next;
        my $r0 = ($t->{$q} ||= ($ri->{_multi} && !$direct ? [[], {}] : [[]]))->[0];
        $ri->{_multi} ? push(@$r0, $x) : ($r0->[0] = $x);
    }
    
    $row->_relate_vfk_($_->[0], $dr0->{$_->[1]}, $direct, 0, 1, $x, $_->[1], $d) for @sync;
}

1;
