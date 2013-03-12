use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    CORE::rename($os->ensure_path(shift), $os->ensure_path(shift));
};
