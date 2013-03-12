package Flapp::Template::Directive::Else;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant BELONGS_TO => 'IF';

sub begin {
    my($dtv, $doc, $ft) = @_;
    $doc->{tmp}{$dtv->{prev_id}} ? ($dtv->{last_id} + 1) : $doc->block($dtv);
}

sub parse { 1 }

1;
