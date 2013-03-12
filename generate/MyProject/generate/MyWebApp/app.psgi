#!/usr/bin/env plackup

BEGIN{
    use Cwd;
    my $lib = Cwd::abs_path(__FILE__) =~ m%^(.+)/[^/]+/[^/]+/[^/]+\z% ? "$1/lib" : die;
    unshift @::INC, $lib if !grep{ $_ eq $lib } @::INC;
}

use MyProject qw/-s -w/;
MyProject->App->Web->no_plack_stacktrace if $::ENV{FLAPP_DEBUG};
use Plack::Builder;
builder {
    my $app = MyProject->app('MyWebApp');
    my $root = $app->app_root.'/public';
    enable 'Static',
        root => $root,
        path => sub{ defined $_ && (s%^/static[0-9A-Za-z_]*/%/static/% || /\.[0-9a-z]+\z/ && -f "$root/$_") };
    $app->psgi;
};
