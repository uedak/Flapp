package Flapp::Template::Directive::Content;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my($i, $n, $d) = ($#{$ft->{doc}}, 1);
    while(--$i >= 0){
        $d = $ft->{doc}[$i];
        my $nm = $d->{body}[$d->{idx}]->name;
        $n += $nm eq 'WRAPPER' ? -1 : $nm eq 'CONTENT' ? 1 : die $nm;
        last if !$n;
    }
    die 'No WRAPPER' if $i < 0;
    ($d = $d->clone)->{idx}++;
    push @{$ft->{doc}}, $d;
    $dtv->{id};
}

sub parse { 1 }

1;
