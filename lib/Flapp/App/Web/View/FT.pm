package Flapp::App::Web::View::FT;
use Flapp qw/-b Flapp::App::Web::View -m -s -w/;

use constant CONFIG => {};

sub open {
    my($self, $c, $loc) = @_;
    my $proj = $c->project;
    my $p = $self->_global_->{parser} ||= $proj->Template->Parser->new({
        STAT_TTL => ($c->debug ? 1 : 0),
        %{$self->CONFIG},
    });
    $p->open($loc)->init({
        stash       => {%{$c->stash}, c => $c, $proj => $proj},
        context     => $c,
        auto_filter => [qw/html/],
    });
}

1;
