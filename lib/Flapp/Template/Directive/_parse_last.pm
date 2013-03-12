use Flapp qw/-m -s -w/;

sub {
    my($dtv, $sr, $p) = @_;
    $dtv->{code} = $p->compile($sr) || return if $$sr =~ s/^IF[\t\n\r ]+//;
    1;
};
