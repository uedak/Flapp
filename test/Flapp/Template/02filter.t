use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

if(!eval{ require Plack }){
    $::INC{'Plack/Request.pm'} = $::INC{'Plack/Response.pm'} = $::INC{'HTTP/Body.pm'} = 1;
    no warnings;
    *Plack::Request::new = *Plack::Response::new = sub{};
}

use MyProject;
is (MyProject->Template, 'MyProject::Template');

my $P = MyProject->Template->Parser;
MyProject->begin;
my $p = $P->new;
my %opt = (context => MyProject->app('MyWebApp')->new({}), auto_filter => [qw/html/]);

{
    my $ft = $p->open(\'[% foo | commify %]');
    is $ft->init({stash => {foo => 100}, %opt})->render, '100';
    is $ft->init({stash => {foo => 1000}, %opt})->render, '1,000';
    is $ft->init({stash => {foo => -10000.1}, %opt})->render, '-10,000.1';
    is $ft->init({stash => {foo => '<+100000.0>'}, %opt})->render, '&lt;+100,000.0&gt;';
}

{
    my $ft = $p->open(\'[% foo | inline %]');
    is $ft->init({stash => {foo => "a\nb"}, %opt})->render, 'a b';
    
    $ft = $p->open(\'[% foo | inline | html_attr %]');
    is $ft->init({stash => {foo => "a\nb"}, %opt})->render, 'a b';
}

{
    my $ft = $p->open(\'[% foo | nvl(bar) %]');
    is $ft->init({stash => {bar => '<b>'}, %opt})->render, '&lt;b&gt;';
    is $ft->init({stash => {foo => undef, bar => '<b>'}, %opt})->render, '&lt;b&gt;';
    is $ft->init({stash => {foo => '', bar => '<b>'}, %opt})->render, '&lt;b&gt;';
    is $ft->init({stash => {foo => 0, bar => '<b>'}, %opt})->render, '0';
    is $ft->init({stash => {}, %opt})->render, '';
}
