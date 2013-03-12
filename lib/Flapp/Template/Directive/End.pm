package Flapp::Template::Directive::End;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin { goto $_[0]->{end} }

sub new {
    my($class, $d, $sr, $p) = @_;
    my $dtv = shift->SUPER::new(@_);
    my $s = pop @{$p->{stack}} || $p->raise('No begin directive', $dtv);
    my $top = shift @$s;
    $top->chain($s, $dtv);
    $dtv->{end} = $top->can('end');
    $dtv;
}

sub parse { 1 }

1;
