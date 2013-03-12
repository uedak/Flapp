use Flapp qw/-m -s -w/;

sub {
    my($os, $dir) = @_;
    my @ls;
    $os->opendir(my $D, $dir) || return undef;
    while(my $f = readdir($D)){
        next if substr($f, 0, 1) eq '.';
        push(@ls, $f);
    }
    closedir($D);
    [sort @ls];
};
