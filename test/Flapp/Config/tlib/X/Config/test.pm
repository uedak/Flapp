package X::Config;
use strict;
use warnings;

sub{
    my($self, $cfg) = @_;
    
    $cfg->{foo}{bar}[0]{baz}++;
    $cfg->{foo}{bar}[1]{baz} = 2;
    $cfg;
}
