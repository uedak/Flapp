use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    CORE::opendir($_[0], $os->ensure_path($_[1]));
};
