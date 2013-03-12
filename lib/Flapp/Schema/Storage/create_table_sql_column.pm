use Flapp qw/-m -s -w/;

sub{
    my($self, $sch, $ci) = @_;
    my $sql = "$ci->{name} $ci->{-t}";
    $sql .= "($ci->{-s})" if defined $ci->{-s};
    $sql .= ' NOT NULL' if !$ci->{-n};
    $sql;
};
