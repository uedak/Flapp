package Flapp::App::Web::Tag;
use Flapp qw/-b Flapp::Object -m -s -w/;

use constant NO_FILLIN_INPUT_TYPES => {map{ $_ => 1 } qw/button file image reset submit/};

sub attr {
    my($self, $n) = (shift, shift);
    my $c = $self->{context};
    my $attr;
    $_->[0] eq $n && ($attr = $_) && last for @{$self->{attrs}};
    if(@_){
        push @{$self->{attrs}}, $attr = [$n] if !$attr;
        $attr->[2] = defined($attr->[1] = shift) ? '="'.$c->html_attr($attr->[1]).'"' : undef;
        return $self;
    }
    $attr && defined $attr->[1] ? $c->html_attr2str($attr->[1]) : undef;
}

sub _fd_ar {
    my($self, $fd, $n, $opt) = @_;
    
    if($opt->{inflate} && $n =~ /^([^[\]]+)\[/gc){
        my @n = ($1);
        push @n, $1 while $n =~ /\G([^[\]]+)\]((\[\])?\z|\[)/gc;
        if(pos $n == length $n){
            $fd = UNIVERSAL::isa($fd, 'HASH') && exists($fd->{$_}) ? $fd->{$_} :
                UNIVERSAL::isa($fd, 'ARRAY') && /^[0-9]+\z/ && $_ <= $#$fd ? $fd->[$_] :
                return undef for @n;
            return ref $fd eq 'ARRAY' ? $fd : [$fd];
        }
    }
    !exists $fd->{$n} ? undef : ref $fd->{$n} eq 'ARRAY' ? $fd->{$n} : [$fd->{$n}];
}

sub _fd_ar_has {
    my($self, $fd_ar, $v, $opt) = @_;
    no warnings;
    $_ eq $v && return 1 for @$fd_ar;
    !1;
}

sub _fd_ar_to_s {
    my($self, $fd_ar, $opt) = @_;
    warn $self->dump($fd_ar).' => '.$self->to_s if @$fd_ar != 1;
    defined $fd_ar->[0] ? $fd_ar->[0] : '';
}

sub fillin {
    my($self, $fd, $n, $opt, $cache) = @_;
    my $fillin = "fillin_$self->{name}";
    $cache->{$n} = $self->_fd_ar($fd, $n, $opt) if !exists $cache->{$n};
    $cache->{$n} ? $self->$fillin($cache->{$n}, $opt) : $self->to_s;
}

sub fillin_input {
    my($self, $fd_ar, $opt) = @_;
    my $t = $self->attr('type');
    $t = defined $t ? lc $t : '';
    return $self->to_s if $t && $self->NO_FILLIN_INPUT_TYPES->{$t};
    if($t eq 'checkbox' || $t eq 'radio'){
        my $v = $self->attr('value');
        $self->toggle_attr(checked => $self->_fd_ar_has($fd_ar, $v, $opt)) if defined $v;
    }elsif(!$t || $t ne 'password' || $opt->{password}){
        $self->attr(value => $self->_fd_ar_to_s($fd_ar, $opt));
    }
    $self->to_s;
}

sub fillin_option {
    my($self, $fd_ar, $opt) = @_;
    my $v = $self->attr('value');
    $v = $self->{context}->html_attr2str($1) if !defined $v && ${$self->{sr}} =~
        /\G(?=[\t\n\r ]*([^<>]+?)[\t\n\r ]*<\/option\b[^<>]*>)/igc;
    $self->toggle_attr(selected => $self->_fd_ar_has($fd_ar, $v, $opt)) if defined $v;
    $self->to_s;
}

sub fillin_textarea {
    my($self, $fd_ar, $opt) = @_;
    ${$self->{sr}} =~ /<\/textarea\b[^<>]*>/igc || return $self->to_s;
    $self->to_s.$self->{context}->html_attr($self->_fd_ar_to_s($fd_ar, $opt)).'</textarea>';
}

sub new {
    my $self = shift->_new_({context => shift, name => lc shift, sr => shift, attrs => []});
    my($n, %h);
    
    !$h{$n = lc $1}++ && push @{$self->{attrs}}, [$n, $+, $2] while ${$self->{sr}} =~
        /\G[\t\n\r ]+([\-0-9A-Za-z_]+)([\t\n\r ]*=[\t\n\r ]*("([^"]*)"|'([^']*)'|[^\t\n\r >]+))?/gc;
    ${$self->{sr}} =~ m%\G([\t\n\r ]*/?>)%gc || return undef;
    $self->{end} = $1;
    $self;
}

sub remove_attr {
    my($self, $n) = @_;
    my $i = 0;
    $_->[0] eq $n && splice(@{$self->{attrs}}, $i, 1) ? last : $i++ for @{$self->{attrs}};
    $self;
}

sub toggle_attr { $_[2] ? $_[0]->attr($_[1] => $_[1]) : $_[0]->remove_attr($_[1]) }

sub to_s {
    my $self = shift;
    "<$self->{name}".join('', map{ " $_->[0]".($_->[2] || '') }@{$self->{attrs}}).$self->{end};
}

1;
