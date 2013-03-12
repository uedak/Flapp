package Flapp::Template::Directive::Elsif;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant BELONGS_TO => 'IF';

sub begin {
    my($dtv, $doc, $ft) = @_;
    $doc->{tmp}{$dtv->{prev_id}} ? ($dtv->{last_id} + 1) :
    ($doc->{tmp}{$dtv->{id}} = $dtv->{code}->($doc) && 1) ? $doc->block($dtv) : $dtv->{next_id};
}

1;
