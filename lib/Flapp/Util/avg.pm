use Flapp qw/-m -s -w/;

sub{
    my $u = shift;
    $u->sum(@_) / @_;
};
