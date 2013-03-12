use Flapp qw/-m -s -w/;

my $a2h = sub{ my $i = 0; +{map{ $_ => $i++ } @{$_[0]}} };
my $W = $a2h->([0 .. 9, 'A' .. 'Z', 'a' .. 'z']);
my $MAX = 999999999999999;

sub{
    my($w, $i) = ($_[2] ? $a2h->($_[2]) : $W, 0);
    my $x = keys %$w;
    my $d = $x ** length($_[1]);
    $i += ($d /= $x) * $w->{$_} for split //, $_[1];
    die "Too large($_[1])" if $i > $MAX;
    $i;
};
