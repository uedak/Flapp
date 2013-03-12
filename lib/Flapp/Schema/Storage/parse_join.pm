use Flapp qw/-m -s -w/;

sub{
    my($self, $join, $ji, $p, $sr, $xr, $left) = @_;
    my $pri = $p->{schema}->relation_info;
    
    foreach my $jn (sort grep{ substr($_, 0, 1) ne '-' } keys %$join){
        my $opt = $join->{$jn} || die qq{No join option for "$jn"};
        my $as = ref $opt eq 'HASH' && defined $opt->{-as} ? $opt->{-as} : $jn;
        die qq{Non-unique join alias "$as"} if $ji->{$as};
        my $j = $ji->{$as} = {-as => $as, depth => $p->{depth} + 1};
        
        my($on, $m);
        if(ref $opt eq 'HASH'){ #existing relationship
            $j->{_ri} = my $ri = $pri->{$jn} || die $p->{schema}->_dmsg_(9, $jn);
            $j->{schema} = $ri->{schema};
            $on = join(' AND ', map{ "$as.$_->[0] = $p->{-as}.$_->[1]" } @{$ri->{on}});
            $m = $ri->{-m};
        }else{
            (my $sn, $opt) = @$opt;
            die qq{Can't join $sn as existing relationship "$jn"} if $pri->{$jn};
            $j->{schema} = $p->{schema}->SCHEMA_BASE->$sn;
            $on = $self->sql_where($opt->{-on} || die qq{No join condition for "$jn"}, $xr);
            $m = $opt->{-m};
        }
        $m = $j->{schema}->_multiplicity_($m, $jn);
        $j->{_multi} = $m->{multi};
        
        my $t = $j->{schema}->table || die "No table for $j->{schema}";
        $$sr .= "\n".(($left || $m->{outer}) ? 'LEFT ' : '')."JOIN $t $as ON $on";
        push @{$p->{children} ||= []}, $j;
        $self->_weaken_($j->{parent} = $p);
        
        $self->parse_join($opt, $ji, $j, $sr, $xr, $left || $m->{outer}) if $j->{_ri};
    }
};
