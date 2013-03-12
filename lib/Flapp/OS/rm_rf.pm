use Flapp qw/-m -s -w/;

my $rm_rf;
$rm_rf = sub{
    CORE::opendir(my $D, $_[0]) || die "$!($_[0])";
    while(my $f = readdir($D)){
        next if $f eq '.' || $f eq '..';
        $f = "$_[0]/$f";
        (!-d $f || -l $f) ? CORE::unlink $f || die "$!($f)" : $rm_rf->($f);
    }
    CORE::closedir($D);
    CORE::rmdir($_[0]) || die "$!($_[0])";
};

sub{
    my $os = shift;
    my $f = $os->ensure_path(shift);
    !-e $f ? 0 : (!-d $f || -l $f) ? CORE::unlink($f) || die "$!($f)" : $rm_rf->($f);
};
