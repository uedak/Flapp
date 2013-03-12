use Flapp qw/-m -s -w/;

sub{
    my $util = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    my $tr = shift;
    my $force = shift;
    
    $tr = $util->_global_->{tr}{$tr} ||= do{
        my $txt = $util->_search_inc_by_method_('tr', "tr/$tr.txt") || die qq{No "$tr.txt"};
        my %tr;
        $util->OS->open(my $H, $txt) || die "$!($txt)";
        local $/ = "\n";
        while(my $line = <$H>){
            $line =~ /^([^\t]+)\t(.*)$/ || die "$txt($line)";
            $tr{$1} = $2;
        }
        close($H);
        \%tr;
    };
    
    my($ofs, $pre, @tr) = (0);
    my $utf8 = $Flapp::UTF8 ? (utf8::is_utf8($$r) ? 1 : undef) : 0;
    $util->each_chr_do($r, sub{
        $utf8 = 0 if !defined($utf8) && !utf8::is_utf8($_[0]);
        my $len = pos($$r) - $ofs;
        if(exists $tr->{$_[0]}){
            if($pre && $pre->[2] == $ofs){
                $pre->[1] .= $tr->{$_[0]};
                $pre->[2] += $len;
            }else{
                push @tr, $pre = [$ofs, $tr->{$_[0]}, $ofs + $len];
            }
        }
        $ofs += $len;
    }, {dh => 1, force => $force});
    return $$r if !@tr;
    
    require Encode;
    Encode::_utf8_off($$r);
    $ofs = 0;
    my $s;
    for(@tr){
        $s .= substr($$r, $ofs, $_->[0] - $ofs) if $ofs < $_->[0];
        Encode::_utf8_off($_->[1]);
        $s .= $_->[1];
        $ofs = $_->[2];
    }
    $$r = $s.substr($$r, $ofs);
    Encode::_utf8_on($$r) if $utf8 || !defined $utf8;
    $$r;
};
