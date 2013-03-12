use Flapp qw/-m -s -w/;

sub{
    my($util, $n, $f) = @_;
    $f ||= 0;
    $n = int(($n * (10 ** $f)) + (($n > 0) ? 0.5 : -0.5)) / (10 ** $f);
    $n = sprintf("%.${f}f", $n) if $f >= 0;
    $n;
};
