use Flapp qw/-m -s -w/;
use Encode;

my $a2r = sub{
    join("\t", map{
        !defined($_) ? '' :
        $_ eq ''     ? '""' : do{
            Encode::_utf8_off(my $s = $_);
            $s =~ s/([\t\n\r"\\])/$Flapp::Util::TSV_ESC->{$1} || die $1/eg if /[\t\n\r"\\]/;
            $s;
        };
    } @_)
};

sub{
    shift;
    return $a2r->(@_) if !$Flapp::UTF8;
    Encode::_utf8_on(my $r = $a2r->(@_));
    $r;
};
