use Flapp qw/-m -s -w/;

sub{
    join('::', map{
        join('', map{
            s/^([a-z])([0-9a-z]*)\z/uc($1).$2/e || return undef;
            $_;
        }split(/_/, $_, -1))
    }split('/', $_[1], -1));
};
