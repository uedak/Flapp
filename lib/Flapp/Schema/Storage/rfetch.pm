use Flapp qw/-m -s -w/;

sub{
    my($self, $ar, $j, $p, $rs) = @_;
    
    my @pk = @$ar[@{$j->{pk_idxs}}];
    return $j->{_ri} ? $p->_set_related_($j->{_ri}, []) :
        ($p->_data_->{-join}{$j->{-as}} = ($j->{_multi} ? [] : undef)) if !defined $pk[0]; #outer
    
    my $r = $j->{r}{join "\0", @pk} ||= do{
        my $r = {};
        @$r{@{$j->{nms}}} = @$ar[@{$j->{idxs}}];
        $r = $j->{schema}->instantiate($r);
        push(@$rs, $r) if !$p;
        $r;
    };
    
    $j->{_ri} ? $p->_relate_($j->{_ri}, $r, 1) :
    $j->{_multi} ? push(@{$p->_data_->{-join}{$j->{-as}} ||= []}, $r) :
    ($p->_data_->{-join}{$j->{-as}} = $r) if $p;
    
    return if !$j->{children};
    $self->rfetch($ar, $_, $r) for @{$j->{children}};
};
