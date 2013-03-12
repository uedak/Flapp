use Flapp qw/-m -s -w/;

sub{
    my($self, $row, $rn, $opt) = @_;
    my $ri = $row->relation_info($rn);
    die qq{Can't save belongs_to relationship "$rn"} if $ri->{type} eq 'belongs_to';
    return !1 if !$row->_related_($ri);
    my $rsch = $ri->{schema};
    my $rs = $row->get_related($rn);
    my $d = $opt->{-d} ? $row->_join_conditions_($ri) || die : undef;
    if($ri->{_multi}){
        my @upd = grep{ $_->in_storage } @$rs;
        if($d){
            my %on = map{ $_->[0] => 1 } @{$ri->{on}};
            if(@upd && (my @rpk = grep{ !$on{$_} } @{$rsch->primary_key || die $rsch->_dmsg_(7)})){
                my($not, $j, $q) = @rpk == 1 ? ("$rpk[0] NOT IN", ',', '?') :
                    ('NOT', ' OR ', join(' AND ', map{ "$_ = ?" } @rpk));
                push @$d, ["$not (".join($j, map{ $q } @upd).')', map{ @{$_->{-org}}{@rpk} } @upd];
            }
            $rsch->delete_by_sql($d);
        }else{
            my %upd = map{ $_->_rowid_ => 1 } @upd;
            !$upd{$_->_rowid_} && $_->delete for @{$row->search_related($rn)};
        }
        $_->save for @$rs;
    }else{
        my $r;
        $d ? $rsch->delete_by_sql($d) :
        ($r = $row->search_related($rn)) && $r->delete if !$rs || !$rs->in_storage;
        $rs->save if $rs;
    }
    
    1;
};
