use Flapp qw/-m -s -w/;

sub{
    my($self, $row, $_org, $_txn, $opt) = @_;
    my $t = $row->table;
    my $ins = $opt->{ins} || [];
    
    my $cnt = int $self->dbh->prepare_cached(
        "INSERT INTO $t (".join(', ', @$ins).
        ') VALUES ('.join(', ', map{ $self->placeholder_for($t, $_) } @$ins).')'
    )->execute(@$_org{@$ins});
    
    die $cnt if $cnt != 1;
    
    $cnt;
};
