package Flapp::Template::Filter;
use Flapp qw/-b Flapp::Object -m -s -w/;

sub commify {
    my($self, $r) = @_;
    $self->Util->commify($r) if ref($r) eq 'SCALAR';
    $r;
}

sub html {
    my($self, $r) = @_;
    $self->{T}->context->html($r) if ref($r) eq 'SCALAR' && !$self->{html}++;
    $r;
}

sub html_attr {
    my($self, $r) = @_;
    $self->{T}->context->html_attr($r) if ref($r) eq 'SCALAR' && !$self->{html}++;
    $r;
}

sub inline {
    my($self, $r) = @_;
    $$r =~ s/(?:[\t ]*[\n\r][\t ]*)+/ /g if ref($r) eq 'SCALAR';
    $r;
}

sub nvl {
    my($self, $r) = (shift, shift);
    $$r = shift if ref($r) eq 'SCALAR' && $$r eq '';
    $r;
}

sub raw {
    my($self, $r) = @_;
    $self->{raw} = 1;
    $r;
}

1;
