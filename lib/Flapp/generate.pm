use Flapp qw/-m -s -w/;
use File::Find;

sub{
    my($proj, $from, $to, $dst, $opt) = @_;
    my $src = $proj->root_dir."/generate/$from";
    die "$!($src)" if !-d $src;
    my $len = length($src);
    my $os = $proj->OS;
    my %ig = map{ $_ => 1 } @{$opt->{ignore} || []};
    my $ig;
    print "   base: $dst/\n";
    
    find({
        no_chdir => 1,
        wanted => sub{
            return if /\/\./; #.svn or .gitkeep
            (my $rel = substr($_, $len)) =~ s%^/%%;
            return if $ig{$rel} && ($ig = qr/^\Q$rel\E/) || $ig && $rel =~ $ig;
            $rel =~ s/\Q$from\E/$to/g;
            my $path = "$dst/$rel";
            
            if(-l $_){
                my $ln = readlink($_);
                symlink($ln, $path) || die "$!($path -> $ln)";
                print "   link: $rel -> $ln\n";
            }elsif(-d $_){
                $os->mkdir($path) || die "$!($path)";
                #print "  mkdir: $rel\n" if $rel ne '';
            }elsif(-f $_){
                return if /\.log\z/;
                $os->cat(my $buf, '<', $_) || die "$!($_)";
                $buf =~ s/\Q$from\E/$to/g;
                $os->cat($buf, '>', $path) || die "$!($path)";
                $os->chmod((stat($_))[2], $path) || die "$!($path)";
                print " create: $rel\n";
            }else{
                die $_;
            }
        },
    }, $src);
};
