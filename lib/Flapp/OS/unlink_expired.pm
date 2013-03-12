use Flapp qw/-m -s -w/;

sub{
    my($os, $dir, $x) = @_;
    $os->opendir(my $D, $dir) || die "$!($dir)";
    my $cnt = 0;
    while(my $f = readdir($D)){
        next if substr($f, 0, 1) eq '.' || (stat("$dir/$f"))[9] > $x;
        $os->unlink("$dir/$f") ? $cnt++ : warn "$!($dir/$f)";
    }
    close($D);
    $cnt;
};
