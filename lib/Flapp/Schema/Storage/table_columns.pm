use Flapp qw/-m -s -w/;

sub{
    my($self, $t) = @_;
    my $sql = "SELECT * FROM $t";
    $self->sql_limit(\$sql, 0);
    (my $sth = $self->dbh->prepare($sql))->execute;
    $sth->{NAME_lc};
};
