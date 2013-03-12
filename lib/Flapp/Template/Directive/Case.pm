package Flapp::Template::Directive::Case;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant BELONGS_TO => 'SWITCH';

my $eq_nw = sub{ no warnings 'uninitialized'; $_[0] eq $_[1] };
my $eq_w  = sub{ $_[0] eq $_[1] };

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $vr = $doc->{tmp}{$dtv->{first_id}} || return $dtv->{last_id} + 1;
    
    my $ok;
    if($dtv->{code}){
        my $eq = $doc->{warnings} ? $eq_w : $eq_nw;
        my $v = $dtv->{code}->($doc);
        if(ref $v eq 'ARRAY'){
            ($ok = $eq->($$vr, $_)) && last for @$v;
        }else{
            $ok = $eq->($$vr, $v)
        }
    }else{
        $ok = 1;
    }
    
    ($ok && delete $doc->{tmp}{$dtv->{first_id}}) ? $doc->block($dtv) : $dtv->{next_id};
}

sub parse {
    my($dtv, $sr, $p) = @_;
    my($code, $src) = $p->compile($sr);
    $dtv->{code} = $code if $code && $src ne '';
    1;
}

1;
