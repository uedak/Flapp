use Flapp qw/-m -s -w/;

sub{
    my($self, $sch, $ci) = @_;
    my $sql = "$ci->{name} $ci->{-t}";
    $sql .= "($ci->{-s})" if defined $ci->{-s};
    $sql .= " CHARACTER SET $ci->{-x}{charset}" if $ci->{-x} && $ci->{-x}{charset};
    $sql .= ' UNSIGNED' if $ci->{-u} && $ci->{-t} ne 'serial';
    $sql .= ' NOT NULL' if !$ci->{-n};
    $sql;
};
