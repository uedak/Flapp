use Flapp qw/-m -s -w/;

sub{
    shift;
    my $sum = shift;
    $sum += $_ for @_;
    $sum;
};
