package Flapp::Template::Directive::While;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    
    if(!$dtv->{code}->($doc)){
        delete $doc->{tmp}{$dtv->{id}};
        return $dtv->{next_id} + 1;
    }
    my $lp = $doc->{tmp}{$dtv->{id}} ||= $ft->Loop->_new_([-1]);
    $lp->[0]++;
    $doc->block($dtv, {local => {loop => $lp}});
}

sub end { shift->{prev_id} }

1;
