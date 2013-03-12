use Flapp qw/-m -s -w/;

sub{
    map{
        $_ eq '' ? undef :
        $_ eq '""' ? '' :
        do{ s/(\\.)/$Flapp::Util::TSV_ESC->{$1} || die $1/eg; $_ }
    } split(/\t/, $_[1], -1);
};
