use Flapp qw/-m -s -w/;

no utf8;
my $u2 = '[\xC2-\xDF][\x80-\xBF]';
my $u3 = '[\xE0-\xEF][\x80-\xBF]{2}';
my $u4 = '[\xF0-\xF7][\x80-\xBF]{3}';
my $reg1 = qr/([\x00-\x7F]|$u3|$u2|$u4)|(.)/;
my $reg2 = qr/([\x00-\x7F]|$u3(\xEF\xBE[\x9E\x9F])?|$u2|$u4)|(.)/;

my %DH;
$DH{$_.'ﾞ'} = 1 for qw/ｳ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ/;
$DH{$_.'ﾞ'} = $DH{$_.'ﾟ'} = 1 for qw/ﾊ ﾋ ﾌ ﾍ ﾎ/;

sub {
    my $util = shift;
    my $sr = ref $_[0] ? shift : do{ \(my $s = shift) };
    my $cb = shift;
    my $opt = shift || {};
    
    my $sif = $opt->{stop_if_false};
    my($f, $s, $c, $m);
    
    my $reg = $opt->{dh} ? $reg2 : $reg1;
    if($Flapp::UTF8){
        $f = utf8::is_utf8($$sr);
        require Encode;
        Encode::_utf8_off($$sr);
        while($$sr =~ /$reg/g){
            if(!defined $1){
                defined($m = $+) && last if !$opt->{force};
                $cb->($+) || $sif && ($s = 1) && last;
            }elsif($2 && !$DH{$1}){
                Encode::_utf8_on($c = substr($1, 0, 3));
                $cb->($c) || $sif && ($s = 1) && last;
                Encode::_utf8_on($c = $2);
                $cb->($c) || $sif && ($s = 1) && last;
            }else{
                Encode::_utf8_on($c = $1);
                $cb->($c) || $sif && ($s = 1) && last;
            }
        }
    }else{
        while($$sr =~ /$reg/g){
            if(!defined $1){
                defined($m = $+) && last if !$opt->{force};
                $cb->($+) || $sif && ($s = 1) && last;
            }elsif($2 && !$DH{$1}){
                $cb->(substr($1, 0, 3)) || $sif && ($s = 1) && last;
                $cb->($2) || $sif && ($s = 1) && last;
            }else{
                $cb->($1) || $sif && ($s = 1) && last;
            }
        }
    }
    pos $$sr = 0;
    Encode::_utf8_on($$sr) if $f;
    defined $m ? die 'Malformed UTF-8 character "\\x'.unpack('H*', $m).'"' : !$s;
};
