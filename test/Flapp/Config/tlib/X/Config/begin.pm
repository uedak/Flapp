package X::Config;
use strict;
use warnings;

sub{
    my $cfg = {
        foo => {
            bar => [
                {baz => 1},
            ],
        },
    };
}
