#!/usr/bin/perl

BEGIN{
    use Cwd;
    my $lib = Cwd::abs_path(__FILE__) =~ m%^(.+)/[^/]+/[^/]+/[^/]+\z% ? "$1/lib" : die;
    unshift @::INC, $lib if !grep{ $_ eq $lib } @::INC;
}

use IO::Handle;
STDOUT->autoflush;
use MyProject qw/-s -w/;
MyProject->app('Tool')->run(@ARGV);
