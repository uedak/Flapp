package Flapp::Template::Directive::Block;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin {
    my($dtv, $doc, $ft) = @_;
    $doc->{$dtv->{scope}}{$dtv->{nm}} = [$doc, $dtv];
    $dtv->{next_id} + 1;
}

sub end { shift->_end_block(@_) }

sub parse {
    my($dtv, $sr, $p) = @_;
    $$sr =~ s/^(([A-Z]?)[0-9A-Za-z_]*)// || return;
    @$dtv{qw/nm scope/} = ($1, $2 ? 'our' : 'my');
    1;
}

1;
