use Flapp qw/-m -s -w/;

sub{
    join('/', map{
        s/(^|[^A-Z])([A-Z]+)/($1 && $1.'_').lc($2)/eg;
        $_;
    }split('::', $_[1], -1));
};
