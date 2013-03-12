use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    my $cmd = $os->ensure_path_or_safecmd(@_);
    local $::ENV{PATH} = $::ENV{PATH} =~ /(.+)/ && $1 if $os->in_taint_mode;
    CORE::system($cmd);
};
