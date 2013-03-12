use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

eval{ require Plack } || plan(skip_all => 'Plack not installed');
plan('no_plan');

use MyProject;
ok my $proj = 'MyProject';
is my $app = $proj->app('MyWebApp'), 'MyProject::MyWebApp';
$proj->begin;

{
    my $c = $app->new({});
    ok my $s = $c->session;
    is $s->id, undef;
    
    is $s->get('foo'), undef;
    is $s->id, undef;
    
    $c->finalize_session;
    is $s->id, undef;
}

{
    my $c = $app->new({});
    ok my $s = $c->session;
    is $s->id, undef;
    
    $s->set('foo','123');
    is $s->id, undef;
    is $s->get('foo'), '123';
    is $s->id, undef;
    
    $c->finalize_session;
    ok my $f = $c->session_dir.'/'.(my $sid = $s->id).'.ses';
    ok -f $f;
    
    $c = $app->new({});
    $s = $c->session;
    $s->{id} = $sid;
    is $c->session->get('foo'), '123';
    ok -f $f;
    unlink $f;
    is $c->session->get('foo'), '123';
}

{
    my $c = $app->new({});
    ok my $s = $c->session;
    is $s->id, undef;
    
    $s->set('foo','123');
    $c->finalize_session;
    ok my $f = $c->session_dir.'/'.(my $sid = $s->id).'.ses';
    ok -f $f;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->get('foo'), 123;
    $s->remove('foo');
    ok -f $f;
    $c->finalize_session;
    ok !-f $f;
}

{
    my $c = $app->new({});
    $c->dispatch('/404');
    $c->session->get('foo');
    my $out = $c->finalize;
    is $out->[0], 404;
    is_deeply $out->[1], ['Content-Type', 'text/plain'];
    is_deeply $out->[2], ['404 Not Found'];
}

{
    my $c = $app->new({});
    ok my $s = $c->session;
    is $s->id, undef;
    
    $c->flash('foo', 'FOO');
    $c->flash_now('bar', 'BAR');
    is $c->flash('foo'), undef;
    is $c->flash_now('foo'), undef;
    is $c->flash('bar'), 'BAR';
    is $c->flash_now('bar'), 'BAR';
    is $s->id, undef;
    
    $c->finalize_session;
    ok my $f = $c->session_dir.'/'.(my $sid = $s->id).'.ses';
    ok -f $f;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->id, $sid;
    is $c->flash('foo'), 'FOO';
    is $c->flash_now('foo'), 'FOO';
    is $c->flash('bar'), undef;
    is $c->flash_now('bar'), undef;
    $c->flash_keep;
    $c->finalize_session;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->id, $sid;
    is $c->flash('foo'), 'FOO';
    is $c->flash_now('foo'), 'FOO';
    is $c->flash('bar'), undef;
    is $c->flash_now('bar'), undef;
    $c->finalize_session;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->id, $sid;
    is $c->flash('foo'), undef;
    is $c->flash_now('foo'), undef;
    is $c->flash('bar'), undef;
    is $c->flash_now('bar'), undef;
    
    unlink $f;
}

{
    my $c = $app->new({});
    ok my $s = $c->session;
    is $s->id, undef;
    
    $c->session->set(foo => {foo => 1});
    $c->session->set(bar => {bar => 2});
    is $s->id, undef;
    $c->finalize_session;
    ok my $f = $c->session_dir.'/'.(my $sid = $s->id).'.ses';
    ok -f $f;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->get('foo')->{foo}, 1;
    is $s->get('bar')->{bar}, 2;
    $s->set(foo => {foo => 3});
    $s->get('bar')->{bar} = 4;
    $c->finalize_session;
    
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->get('foo')->{foo}, 3;
    is $s->get('bar')->{bar}, 2;
    
    unlink $f;
}

{
    my $c = $app->new({});
    my $sid = '0' x 40;
    ok my $f = $c->session_dir."/$sid.ses";
    unlink $f;
    
    ok my $s = $c->session;
    $c->finalize_session;
    is $s->id, undef;
    
    ok !-f $f;
    $c = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
    $s = $c->session;
    is $s->ensure_id, $sid;
    ok !-f $f;
}

{
    my $sid = '0' x 40;
    local $::INC{'Encode/JP/Emoji.pm'} = 1;
    my $c = $app->new({
        HTTP_HOST => 'test.com',
        REQUEST_URI => '/',
        HTTP_USER_AGENT => 'SoftBank',
        QUERY_STRING => ".sid=$sid",
    });
    my $s = $c->session->set(foo => 1);
    is $s->state->_class_, 'MyProject::App::Web::Session::State::Url';
    
    $c->res->body(qq{<a href=""></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="?.sid=$sid"></a>};
    
    $c->res->body(qq{<a href="?"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="?.sid=$sid"></a>};
    
    $c->res->body(qq{<a href="?a=1&amp;.sid=1&b=2#foo"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="?a=1&amp;b=2&amp;.sid=$sid#foo"></a>};
    
    $c->res->body(qq{<a href="foo#bar"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="foo?.sid=$sid#bar"></a>};
    
    $c->res->body(qq{<a href="foo"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="foo?.sid=$sid"></a>};
    
    $c->res->body(qq{<a href="#"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="#"></a>};
    
    $c->res->body(qq{<a href="#foo"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="#foo"></a>};
    
    
    
    $c->res->body(qq{<a href="//test.com"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="//test.com?.sid=$sid"></a>};
    
    $c->res->body(qq{<a href="https://test.com:443/"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="https://test.com:443/?.sid=$sid"></a>};
    
    $c->res->body(qq{<a href="//x.test.com"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="//x.test.com"></a>};
    
    $c->res->body(qq{<a href="//xtest.com"></a>});
    $c->finalize_session;
    is $c->res->body, qq{<a href="//xtest.com"></a>};
    
    $c->res->body(q{<a href="mailto:foo@test.com"></a>});
    $c->finalize_session;
    is $c->res->body, q{<a href="mailto:foo@test.com"></a>};
    
    $c->res->body(q{<form>});
    $c->finalize_session;
    is $c->res->body, qq{<form><input type="hidden" name=".sid" value="$sid" />};
    
    $c->res->body(q{<form method="post" />});
    $c->finalize_session;
    is $c->res->body, qq{<form method="post" action="?.sid=$sid" />};
    
    $c->res->body(q{<meta http-equiv="refresh" content="0; url=/">});
    $c->finalize_session;
    is $c->res->body, qq{<meta http-equiv="refresh" content="0;url=/?.sid=$sid">};
    
    {
        local $s->state->{domain_regexp};
        local $s->state->{domain} = 'test.com';
        $c->res->body(qq{<a href="//test.com"></a>});
        $c->finalize_session;
        is $c->res->body, qq{<a href="//test.com?.sid=$sid"></a>};
        
        $c->res->body(qq{<a href="//x.test.com"></a>});
        $c->finalize_session;
        is $c->res->body, qq{<a href="//x.test.com?.sid=$sid"></a>};
        
        $c->res->body(qq{<a href="//xtest.com"></a>});
        $c->finalize_session;
        is $c->res->body, qq{<a href="//xtest.com"></a>};
    }
    
    {
        my $c = $app->new({
            HTTP_HOST => 'test.com',
            HTTP_USER_AGENT => 'SoftBank',
            QUERY_STRING => ".sid=$sid",
        });
        $c->redirect_for('/');
        $c->finalize_session;
        is $c->res->location, "/?.sid=$sid";
    }
}
$proj->OS->rm_rf($proj->project_root.'/tmp/apps');
