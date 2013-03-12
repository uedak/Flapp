use Flapp qw/-m -s -w/;

sub{
    my($self, $sch, $cnd, $opt) = @_;
    my $t = $sch->table || die "No table for $sch";
    my @x;
    
    my $sql = "DELETE FROM $t";
    $sql .= " WHERE $cnd" if ($cnd &&= $self->sql_where($cnd, \@x));
    $self->sql_limit(\$sql, $opt->{rows}) if $opt->{rows};
    $self->interpolate_sql(\$sql, \@x) if @x;
    
    int $self->dbh->prepare_cached($sql)->execute(@x);
};
