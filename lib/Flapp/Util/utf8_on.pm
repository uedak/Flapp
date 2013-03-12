use Flapp qw/-m -s -w/;
use Encode;

sub{
    Encode::_utf8_on($_[1]);
    return 1 if utf8::valid($_[1]);
    Encode::_utf8_off($_[1]);
    !1;
};
