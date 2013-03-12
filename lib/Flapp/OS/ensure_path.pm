use Flapp qw/-m -s -w/;

sub{
    my $os = shift;
    die 'No arguments' if !defined($_[0]) || $_[0] eq '';
    $os->is_path($_[0]) || die qq{Invalid path: "$_[0]"};
    $_[0];
};
