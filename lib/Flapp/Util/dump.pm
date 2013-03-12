use Flapp qw/-m -s -w/;
use Data::Dumper;
use Encode;

my %JP_ALL;
{
    my $f = Flapp->root_dir.'/lib/Flapp/Validator/chr/jp_all.txt';
    Flapp->OS->open(my $H, '<:utf8', $f) || die "$!($f)";
    local $/ = "\n";
    while(my $line = <$H>){
        chomp $line;
        $JP_ALL{$_} = 1 for split //, $line;
    }
    close($H);
}

my $asc = qr/[ !#%-?A-\[\]-~]/;
my $utf8 = qr/[\xE0-\xEF][\x80-\xBF]{2}|[\xC2-\xDF][\x80-\xBF]|[\xF0-\xF7][\x80-\xBF]{3}/;
my %esc = ("\n" => '\n', "\r" => '\r', "\t" => '\t', qw/" \" $ \$ @ \@ \ \\\\/);
my $qquote = sub{
    return "'$_[0]'" if $_[0] !~ /[^ -&(-\[\]-~]/;
    Encode::_utf8_off(my $s = $_[0]);
    if($Flapp::UTF8 && !utf8::is_utf8($_[0])){ #as bin
        $s =~ s%($asc+)|(.)%defined $1 ? $1 : ($esc{$2} || '\x'.uc(unpack 'H*', $2))%seg;
    }else{
        $s =~ s{($asc+)|($utf8)|(.)}{
            defined $1 ? $1 :
            defined $2 ? do{
                Encode::_utf8_on(my $u = $2);
                $JP_ALL{$u} ? $u : $Flapp::UTF8 ? sprintf('\x{%x}', ord $u) :
                    join('', map{ $esc{$_} || '\x'.uc(unpack 'H*', $_) } split //, $2);
            } : ($esc{$3} || '\x'.uc(unpack 'H*', $3))
        }seg;
    }
    qq{"$s"};
};

sub{
    shift;
    no warnings 'redefine';
    local *Data::Dumper::qquote = $qquote;
    my $d = Data::Dumper
        ->new([@_])
        ->Indent($Flapp::Util::DUMP_INDENT || 0)
        ->Pair(' => ')
        ->Quotekeys(0)
        ->Sortkeys(1)
        ->Terse(1)
        ->Useqq(1)
        ->Dump;
    $Flapp::UTF8 ? Encode::_utf8_on($d) : Encode::_utf8_off($d);
    $d =~ s%((?:\n *(\[\],?|\{\},?|[^\n>\[\]\{\}]*))+\n *)%
        (my $s = $1) =~ s/\n */ /g;
        $s;
    %eg if $Flapp::Util::DUMP_INDENT;
    $d;
};
