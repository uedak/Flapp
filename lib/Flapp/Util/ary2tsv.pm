use Flapp qw/-m -s -w/;
use Encode;

sub{
    shift;
    join("\t", map{
        !defined($_)  ? '' :
        $_ eq ''      ? '""' :
        !/[\t\n\r"\\]/ ? $_ : do{
            Encode::_utf8_off(my $s = $_);
            $s =~ s/([\t\n\r"\\])/$Flapp::Util::TSV_ESC->{$1} || die $1/eg;
            Encode::_utf8_on($s) if $Flapp::UTF8;
            $s;
        };
    }@_);
};
