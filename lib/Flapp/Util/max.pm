use Flapp qw/-m -s -w/;

sub{
    shift;
    my $max = shift;
    $_ > $max && ($max = $_) for @_;
    $max;
};
