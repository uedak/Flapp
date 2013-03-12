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

require Plack::Request::Upload;
if(!Plack::Request::Upload->can('path')){ #for old
    no warnings 'once';
    *Plack::Request::Upload::path = \&Plack::Request::Upload::tempname;
}

my $ct = 'multipart/form-data; boundary=---------------------------54472172614771';

{ #Invalid ext
    open(my $H, "$FindBin::Bin/04request/ok.txt") || die "$!(ok.txt)";
    my $c = $app->new({
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => $ct,
        CONTENT_LENGTH => 183,
        'psgi.input'   => $H,
    });
    
    is $c->req->content_length, 183;
    my $d = $c->upload_dir;
    like $c->req->upload('f')->path, qr%^\Q$d\E/[0-9A-Za-z_]+(\.txt)?\z%;
    
    open($H, "$FindBin::Bin/04request/bad_ext.txt") || die "$!(bad_ext.txt)";
    $c = $app->new({
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => $ct,
        CONTENT_LENGTH => 191,
        'psgi.input'   => $H,
    });
    
    is $c->req->content_length, 191;
    like $c->req->upload('f')->path, qr%^\Q$d\E/[0-9A-Za-z_]+\z%;
}

{ #Bad Content-Length
    my $log = $proj->logger->path;
    $proj->OS->cat('', '>', $log) || die "$!($log)";
    
    my $root = $app->controller('Root');
    is $root, 'MyProject::MyWebApp::Controller::Root';
    
    my $READ;
    no warnings 'once';
    local *MyProject::MyWebApp::Controller::Root::foo = sub{
        my($self, $c) = @_;
        $c->req->upload('f') if $READ;
        $c->res->body('ok');
    };
    $root->MODIFY_CODE_ATTRIBUTES($root->_code_('foo'), 'Action');
    
    $proj->end;
    open(my $H, "$FindBin::Bin/04request/ok.txt") || die "$!(ok.txt)";
    my %env = (
        REQUEST_METHOD => 'POST',
        PATH_INFO      => '/foo',
        CONTENT_TYPE   => $ct,
        CONTENT_LENGTH => 200,
        'psgi.input'   => $H,
    );
    my($res, $buf);
    
    $READ = 1;
    $res = $app->psgi->({%env});
    $res->(sub{ $res = shift });
    is $res->[0], 500;
    $proj->OS->cat($buf, '<', $log) || die "$!($log)";
    $proj->OS->cat('', '>', $log) || die "$!($log)";
    like $buf, qr/^..:..:..\t__DIE__\t.+\n\z/;
    $READ = 0;
    seek $H, 0, 0;
    
    $res = $app->psgi->({%env});
    $res->(sub{ $res = shift });
    is $res->[0], 200;
    is -s $log, 0;
    
    $env{CONTENT_LENGTH} = 183;
    $READ = 1;
    $res = $app->psgi->({%env});
    $res->(sub{ $res = shift });
    is $res->[0], 200;
    is -s $log, 0;
    seek $H, 0, 0;
    
    $proj->begin;
}

{ #Invalid utf8 in params
    my $log = $proj->logger->path;
    $proj->OS->cat('', '>', $log) || die "$!($log)";
    
    my $root = $app->controller('Root');
    is $root, 'MyProject::MyWebApp::Controller::Root';
    
    my($W1, $D1, $W2, $D2);
    local *MyProject::MyWebApp::Controller::Root::foo = sub{
        my($self, $c) = @_;
        warn 'W1' if $W1;
        my $p = $c->req->params;
        warn 'W2' if $W2;
        $c->res->body('ok');
    };
    $root->MODIFY_CODE_ATTRIBUTES($root->_code_('foo'), 'Action');
    
    $proj->end;
    open(my $H, "$FindBin::Bin/04request/invalid_utf8.txt") || die "$!(ok.txt)";
    my %env = (
        REQUEST_METHOD => 'POST',
        PATH_INFO      => '/foo',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => 16,
        'psgi.input'   => $H,
    );
    my($res, $buf);
    
    local $Flapp::UTF8 = 1;
    binmode $proj->logger->{H}, ':utf8';
    
    $res = $app->psgi->({%env});
    $res->(sub{ $res = shift });
    is $res->[0], 200;
    is -s $log, 0;
    seek $H, 0, 0;
    
    $W1 = $W2 = 1;
    $res = $app->psgi->({%env});
    $res->(sub{ $res = shift });
    is $res->[0], 200;
    $proj->OS->cat($buf, '<:raw', $log) || die "$!($log)";
    $proj->OS->cat('', '>', $log) || die "$!($log)";
    seek $H, 0, 0;
    like $buf, qr/^.+{"あ" => "\\x82\\xA0"}\n.+{"あ" => "\\x82\\xA0"}\n\z/;
    
    $proj->begin;
}

$proj->OS->rm_rf($proj->config->log_dir);
$proj->OS->rm_rf($proj->project_root.'/tmp/apps');
