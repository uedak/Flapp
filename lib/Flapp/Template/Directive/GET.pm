package Flapp::Template::Directive::GET;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin {
    my($dtv, $doc, $ft) = @_;
    my $v = $dtv->{code}->($doc);
    my $r = ref $v ? $v : \$v;
    $$r = '' if ref $r eq 'SCALAR' && !defined $$r;
    my $f = $ft->Filter->_new_({T => $ft});
    if($dtv->{filter}){
        foreach(@{$dtv->{filter}}){
            my($m, $ar) = @$_;
            $r = $f->$m($r, !$ar ? () : $ar->($doc));
        }
    }
    my $af = $ft->{auto_filter};
    if($af && @$af && !$f->{raw}){
        $r = $f->$_($r) for @$af;
    }
    $ft->write(ref $r eq 'SCALAR' ? $$r : $r);
    $dtv->{id} + 1;
}

sub parse {
    my($dtv, $sr, $p) = @_;
    $dtv->{code} = $p->compile($sr) || return;
    
    my($F, @f);
    while($$sr =~ s/^[\t\n\r ]*\|[\t\n\r ]+([a-z][0-9a-z_]*)//){
        $F ||= $p->project->Template->Filter;
        $p->raise("Invalid filter($1)", $dtv) if !$F->can($1);
        push @f, my $f = [$1];
        push @$f, $p->compile($sr) || return if $$sr =~ /^\(/;
    }
    $dtv->{filter} = \@f if @f;
    1;
}

1;
