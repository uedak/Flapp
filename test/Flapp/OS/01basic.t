use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;

is my $os = MyProject->OS, 'MyProject::OS';
is $os->project, 'MyProject';

{
    my $f = MyProject->project_root.'/tmp/test.txt';
    
    $os->open(my $H, '>', $f);
    like "$H", qr/^GLOB\(\w+\)/;
    print $H "foo\n";
    close($H);
    
    $os->open($H, '>>', $f);
    print $H "bar\n";
    close($H);
    
    $os->open($H, '<', $f);
    is <$H>, "foo\n";
    is <$H>, "bar\n";
    close($H);
    
    $os->open($H, $f);
    is do{ local $/; <$H> }, "foo\nbar\n";
    close($H);
    
    $os->cat('あいうえお', '>', $f);
    $os->open($H, $f);
    is length <$H>, 15;
    close($H);
    
    {
        local $Flapp::UTF8 = 1;
        $os->open($H, $f);
        is length <$H>, 5;
        close($H);
    }
    
    ok $os->unlink($f);
    ok !-f $f;
}
