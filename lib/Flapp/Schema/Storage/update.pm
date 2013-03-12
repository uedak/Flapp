use Flapp qw/-m -s -w/;

sub{
    my($self, $row, $_org, $_txn, $opt) = @_;
    my $t = $row->table;
    my @set = grep{ $opt->{set}{$_} } @{$row->columns};
    my($org, $w, $i) = (($row->{-org} || die 'Row not in_storage'), $opt->{where});
    $i = [map{ defined($i = $org->{$_}) ? $i : die $row->_dmsg_(6, $_) } @$w];
    
    my $cnt = int $self->dbh->prepare_cached(
        "UPDATE $t SET ".join(', ', map{ "$_ = ".$self->placeholder_for($t, $_) } @set).
        ' WHERE '.join(' AND ', map{ "$_ = ?" } @$w)
    )->execute(@$_org{@set}, @$i);
    
    if($cnt != 1){
        my $q = "$t?".join('&', map{ "$w->[$_]=$i->[$_]" } 0 .. $#$w);
        die !$cnt ? "Row not found ($q)" : "Update $cnt rows ($q)";
    }
    
    $cnt;
};
