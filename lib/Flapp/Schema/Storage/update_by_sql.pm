use Flapp qw/-m -s -w/;

sub{
    my($self, $sch, $cnd, $opt) = @_;
    my $t = $sch->table || die "No table for $sch";
    my(@x, $set);
    
    my $sql = "UPDATE $t";
    $sql .= " SET $set" if ($set = $self->sql_where($opt->{set}, \@x, 0, 1));
    $sql .= " WHERE $cnd" if ($cnd &&= $self->sql_where($cnd, \@x));
    $self->sql_limit(\$sql, $opt->{rows}) if $opt->{rows};
    $self->interpolate_sql(\$sql, \@x) if @x;
    
    int $self->dbh->prepare_cached($sql)->execute(@x);
};
