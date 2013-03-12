use Flapp qw/-m -s -w/;

sub{
    my($c, $src, $fd, $opt) = @_;
    my $r;
    ($r, $src) = ($src, $$src) if ref $src;
    $$r = '';
    
    my($pos, $sn, $fvs, %cache) = (0);
    while($src =~ m%<(input|option|/?select|textarea|!--)%ig){
        $src =~ /-->/gc ? next : last if $1 eq '!--';
        my $tnm = lc $1;
        next if $tnm eq '/select' && !($sn = undef);
        my $p = pos($src) - length($1) - 1;
        my $tag = $c->Tag->new($c, $tnm, \$src) || next;
        my $n = $tnm eq 'option' ? $sn : $tag->attr('name');
        
        if($tnm eq 'select'){
            $sn = $n;
        }elsif(defined $n){
            $$r .= substr($src, $pos, $p - $pos) if $p > $pos;
            $$r .= $tag->fillin($fd, $n, $opt, \%cache);
            $pos = pos $src;
        }
    }
    $$r .= substr($src, $pos) if length($src) > $pos;
    $$r;
};
