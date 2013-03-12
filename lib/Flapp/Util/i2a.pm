use Flapp qw/-m -s -w/;

my @W = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');
my $MAX = 999999999999999;

sub{
    my($i, $w, $s, $d) = ($_[1], $_[2] || \@W, '');
    die "Too large($i)" if $i > $MAX;
    while(1){
        $s = $w->[$d = $i % @$w].$s;
        last if ($i -= $d) <= 0;
        $i /= @$w;
    }
    $s;
};
