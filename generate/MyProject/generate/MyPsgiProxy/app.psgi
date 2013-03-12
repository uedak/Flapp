#!/usr/bin/env plackup

BEGIN{
    use Cwd;
    my $lib = Cwd::abs_path(__FILE__) =~ m%^(.+)/[^/]+/[^/]+/[^/]+\z% ? "$1/lib" : die;
    unshift @::INC, $lib if !grep{ $_ eq $lib } @::INC;
}

use MyProject qw/-s -w/;
MyProject->App->Web->no_plack_stacktrace if $::ENV{FLAPP_DEBUG};
use Plack::Builder;
use Plack::Util;

my $cfg = MyProject->config->apps->MyPsgiProxy;
my $apps = MyProject->project_root.'/apps';
my %psgi;

builder { sub{
    my $env = shift;
    my $uri = "$env->{'psgi.url_scheme'}://$env->{HTTP_HOST}$env->{REQUEST_URI}";
    
    foreach(@$cfg){
        $uri =~ $_->[0] || next;
        return ($psgi{$_->[1]} ||= Plack::Util::load_psgi("$apps/$_->[1]/app.psgi"))->($env);
    }
    [404, ['Content-Type' => 'text/html'], ['404 Not Found']],
} };
