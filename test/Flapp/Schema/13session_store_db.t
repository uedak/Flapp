use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use lib Cwd::abs_path("$FindBin::Bin/tlib");
use strict;
use warnings;

eval{ require Plack } || plan(skip_all => 'Plack not installed');

use MyProject;
use MyTest;
my $proj = 'MyProject';
my($DBH, $DBN) = MyTest->setup($proj);
ok $DBN;

$proj->begin;
eval{
    MyTest->migrate($proj);
    
    my $cfg = $proj->Config->src($proj->config);
    $cfg->{App}{Web}{session}{store} = {DB => {schema => 'ExampleSession'}};
    local $proj->_global_->{config}{$proj->env} = $proj->Config->new($cfg);
    
    {
        is my $app = $proj->app('MyWebApp'), 'MyProject::MyWebApp';
        
        my $c = $app->new({});
        $c->session->set(foo => 1);
        
        tie *STDERR, 'Capture';
        local $::ENV{FLAPP_DEBUG} = 1;
        local $Flapp::NOW = '2012-01-02T03:04:05+0900';
        $c->finalize_session;
        my $sid = $c->session->id;
        
        my $e = Capture->end;
        $e =~ s/'[^']+foo'/?/;
        is $e, <<_END_;
\$(Default:0)->execute("SELECT * FROM example_sessions WHERE id = '$sid'")
\$(Default:0)->execute("INSERT INTO example_sessions (id, data, access_at) VALUES ('$sid', ?, '2012-01-02 03:04:05')")
_END_
    }
    
    {
        is my $app = $proj->app('MyWebApp'), 'MyProject::MyWebApp';
        my $sid = '0' x 40;
        
        tie *STDERR, 'Capture';
        local $Flapp::NOW = '2012-01-02T03:04:05+0900';
        local $::ENV{FLAPP_DEBUG} = 1;
        
        my $c1 = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
        $c1->session->set(foo => 1);
        
        my $c2 = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
        $c2->session->set(foo => 1);
        
        $c1->finalize_session;
        $c2->finalize_session;
        
        my $e = Capture->end;
        $e =~ s/'[^']+foo'/?/g;
        is $e, <<_END_;
\$(Default:0)->execute("SELECT * FROM example_sessions WHERE id = '$sid'")
\$(Default:0)->execute("SELECT * FROM example_sessions WHERE id = '$sid'")
\$(Default:0)->execute("INSERT INTO example_sessions (id, data, access_at) VALUES ('$sid', ?, '2012-01-02 03:04:05')")
\$(Default:0)->execute("INSERT INTO example_sessions (id, data, access_at) VALUES ('$sid', ?, '2012-01-02 03:04:05')")
\$(Default:0)->execute("SELECT data FROM example_sessions WHERE id = '$sid'")
_END_
    }
    
    {
        is my $app = $proj->app('MyWebApp'), 'MyProject::MyWebApp';
        my $sid = '1' x 40;
        
        tie *STDERR, 'Capture';
        local $Flapp::NOW = '2012-01-02T03:04:05+0900';
        local $::ENV{FLAPP_DEBUG} = 1;
        
        my $c1 = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
        $c1->session->set(foo => 1);
        
        my $c2 = $app->new({HTTP_COOKIE => ".sid=$sid; path=/"});
        $c2->session->set(foo => 2);
        
        $c1->finalize_session;
        eval{ $c2->finalize_session };
        
        like $@, qr/^DBD::mysql::st execute failed: Duplicate entry '$sid' for key/;
    }
};
$proj->end;

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;


package Capture;
sub TIEHANDLE { bless \(my $buf = ''), shift }
sub PRINT { ${+shift} .= shift }
sub end {
    (my $s = ${tied *STDERR}) =~ s/^-+\n//mg;
    untie *STDERR;
    $s;
}
