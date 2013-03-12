package Flapp::Template::Directive::Insert;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $src = $dtv->{code}->($doc) || die 'No src';
    $doc->rel2abs(\$src) if substr($src, 0, 1) ne '/';
    my $sr = $doc->{tmp}{$dtv->{id}}{$src} ||= do{
        my $loc = $ft->locate($src);
        $ft->OS->cat(my $s, '<', $loc->[0].$loc->[1]) || die "$!($loc->[0]$loc->[1])";
        \$s;
    };
    $ft->write($$sr);
    $dtv->{id} + 1;
}

1;
