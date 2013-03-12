use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    CORE::chmod(shift, map{ $os->ensure_path($_) } @_);
};
