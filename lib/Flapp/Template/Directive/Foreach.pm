package Flapp::Template::Directive::Foreach;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $lp = $doc->{tmp}{$dtv->{id}} ||= do{
        my $i = $dtv->{code}->($doc);
        if(!UNIVERSAL::isa($i, 'ARRAY')){
            $i = '' if !defined $i;
            die qq{Can't use "$i" as an ARRAY ref while "strict refs" in use} if $doc->{strict};
            $i = undef;
        };
        return $dtv->{next_id} + 1 if !$i || !@$i;
        $ft->Loop->_new_([-1, $i]);
    };
    if(++$lp->[0] > $#{$lp->[1]}){
        delete $doc->{tmp}{$dtv->{id}};
        return $dtv->{next_id} + 1;
    }
    $doc->block($dtv, {local => {loop => $lp, $dtv->{nm} => $lp->[1][$lp->[0]]}});
}

sub end { shift->{prev_id} }

sub parse {
    my($dtv, $sr, $p) = @_;
    $$sr =~ s/^([a-z_][0-9a-z_]*)[\t\n\r ]+IN[\t\n\r ]+// || return;
    $dtv->{nm} = $1;
    $dtv->{code} = $p->compile($sr);
}

1;
