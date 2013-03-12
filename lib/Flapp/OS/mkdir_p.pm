use Flapp qw/-m -s -w/;

sub{
    my($os, $dir) = (shift, shift);
    $dir =~ s%/\z%%;
    my @dir;
    while($dir ne '' && !-d $dir){
        unshift @dir, $dir;
        last if $dir !~ s%/[^/]+\z%%;
    }
    $os->mkdir($_, @_) || return 0 for @dir;
    1;
};
