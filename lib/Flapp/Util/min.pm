use Flapp qw/-m -s -w/;

sub{
    shift;
    my $min = shift;
    $_ < $min && ($min = $_) for @_;
    $min;
};
