use Flapp qw/-m -s -w/;

sub{
    my($self, $row, $_org, $_txn, $opt) = @_;
    my $t = $row->table;
    my($org, $w, $i) = (($row->{-org} || die 'Row not in_storage'), $opt->{where});
    $i = [map{ defined($i = $org->{$_}) ? $i : die $row->_dmsg_(6, $_) } @$w];
    
    my $cnt = int $self->dbh->prepare_cached(
        "DELETE FROM $t WHERE ".join(' AND ', map{ "$_ = ?" } @$w)
    )->execute(@$i);
    
    if($cnt != 1){
        my $q = "$t?".join('&', map{ "$w->[$_]=$i->[$_]" } 0 .. $#$w);
        die !$cnt ? "Row not found ($q)" : "Delete $cnt rows ($q)";
    }
    
    $cnt;
};
