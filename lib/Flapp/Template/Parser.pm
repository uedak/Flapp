package Flapp::Template::Parser;
use Flapp qw/-b Flapp::Object -m -s -w/;

use constant CONFIG => {
    CACHE_SIZE  => 100,
    MARKUP      => [qw/[% - - %]/],
    STAT_TTL    => 0,
    STRICT      => 0,
    TRIM_INDENT => 0,
    WARNINGS    => 0,
};

our %PAIR = qw/( ) < > [ ] { }/;
__PACKAGE__->_mk_accessors_(qw/error/);

sub compile {
    my $self = shift;
    my $sr = ref $_[0] ? shift : do{ \(my $s = shift) };
    my $st = {pos => 0, sub => ''};
    
    $self->{error} = undef;
    if(!$self->_compile($sr, $st)){
        $self->{error} = $st->{error} || 'Syntax error';
        if((my $s = substr($$sr, $st->{pos}, (pos($$sr) || length($$sr)) - $st->{pos})) ne ''){
            $self->{error} .= " near `$s`";
        }
        return;
    }
    my $pos = pos $$sr;
    substr($$sr, 0, $pos) = '' if $pos;
    my $code = eval 'package main; sub{ '.($st->{var} ? $self->{pragma} : '')."$st->{sub} }" || do{
        ($self->{error} = $@) =~ s/ at \(eval [0-9]+\).+/ at eval `$st->{sub}`/s;
        return;
    };
    wantarray ? ($code, $st->{sub}) : $code;
}

sub _compile {
    my($self, $sr, $st, $q) = @_;
    
    while(1){
        my $pos = pos($$sr) || 0;
        $$sr =~ /\G([\t\n\r !]*)(
            ([A-Za-z_][0-9A-Za-z_]*\(?|\$[ab_]\b)
            |(["\(\/\[]|(?:[%@]|\$\#)?{)
            |'(?:\\.|[^'])*'
            |[+\-]?[0-9]+(?:\.[0-9]+)?
            |\$[0-9]+
            |(\#).*
        )/gcx || last;
        $st->{sub} .= $1;
        next if $5; #
        $st->{pos} = $pos if !$q;
        if($3){
            if(substr($3, -1) eq '('){ # [% join(...
                $st->{sub} .= $3;
                $self->_compile($sr, $st, ')') || return;
                $st->{sub} .= ')';
            }else{ # [% foo.bar or foo[1] or foo[bar]
                $self->_compile_var($sr, $st, $3) || return;
                $st->{var} = pos $$sr;
            }
        }elsif($4){
            if($4 eq '"'){
                $self->_compile_qq($sr, $st) || return;
            }elsif($4 eq '/'){
                $st->{sub} .= '/';
                $self->_compile_regexp($sr, $st, $4) || return;
            }else{
                my $p = $4 eq '(' && length $st->{sub};
                $st->{sub} .= $4;
                my $q = $PAIR{$4} || '}';
                my $d = $self->{STRICT} ? '' : $4 eq '@{' ? '[]' : $4 eq '%{' ? '{}' : '';
                $self->_compile($sr, $st, $q) || return;
                $st->{sub} .= $d ? " || $d}" : $q;
                if($q eq ')' && $$sr =~ /\G([.[])/gc){
                    pos($$sr)--;
                    $self->_compile_var($sr, my $_st = {sub => ''}, '') || return;
                    substr($_st->{sub}, 11, 2) = 'sub{ '.substr($st->{sub}, $p + 1, -1).' }';
                    substr($st->{sub}, $p) = $_st->{sub};
                    $st->{var} = pos $$sr;
                }
            }
        }else{
            $st->{sub} .= $2;
        }
        
        my $op = $self->_compile_op($sr, $st, $q);
        return if !defined($op) || !$q && ($op eq ',' || $op eq '=>');
        next if $op || ($q && $q eq ')' && substr($st->{sub}, -1) eq '}'); # grep({ /./ } 1 .. 3)
        last;
    }
    if($q){
        return if $$sr !~ /\G([\t\n\r ]*)\Q$q\E/gc && ($st->{error} = "Missing right bracket '$q'");
        $st->{sub} .= $1 if $1;
    }else{
        return if !pos($$sr);
    }
    
    1;
}

sub _compile_op {
    my($self, $sr, $st) = @_;
    my $v = $st->{var} && pos($$sr) == $st->{var};
    
    $$sr =~ /\G([\t\n\r ]*)(
        [,:?]|\.\.
        |\b(?:eq|[ngl]e|[gl]t|x(?:or)?|cmp)\b
        |[=!]~[\t\n\r ]*(\/|(m|s|tr)[!-\/:-@\[-`{-~])
        |=[=>]|!=|<=>|[<>]=?
        |(?:[%+\-\/_]|\*\*?|&&|\|\|)(=?)
        |=
    )([\t\n\r ]*)/gcx || return '';
    
    ($2 eq '=' || $5 || $4 && $4 ne 'm') ? (substr($st->{sub}, -1) = ", '=')") :
    $2 eq '=>' ? do{ $st->{sub} =~ s/\$_\[0\]->var\('(\-?[0-9A-Za-z_]+)'\)\z/$1/ } : 1 if $v;
    
    $st->{sub} .= $1.($2 eq '_' ? '.' : $2 eq '_=' ? '.=' : $2).$6;
    return $2 if !$3;
    $self->_compile_regexp($sr, $st, $3) || return;
    $self->_compile_op($sr, $st);
}

sub _compile_qq {
    my($self, $sr, $st) = @_;
    
    $st->{sub} .= '"';
    while($$sr =~ /\G((?:\\.|[^"\$@])+|\${|.)/gc){
        if($1 eq '${'){
            $st->{sub} .= '".' if $st->{sub} !~ s/"\z//;
            $st->{sub} .= '(';
            $self->_compile($sr, $st, '}') || return;
            $st->{sub} .= ')."';
        }else{
            $st->{sub} .= ($1 eq '$' || $1 eq '@' ? '\\' : '').$1;
            if($1 eq '"'){
                $st->{sub} =~ s/\.""\z//;
                return 1;
            }
        }
    }
    $st->{error} = q{Can't find string terminator '"' anywhere};
    return;
}

sub _compile_regexp {
    my($self, $sr, $st, $mstr) = @_;
    
    my $q = chop $mstr;
    my $e = $PAIR{$q} || $q;
    while($$sr =~ /\G((?:\\.|[^\Q$e\E\$])+|\${?|.)/gc){
        if($1 eq '${'){
            $st->{sub} .= '(??{ ';
            $self->_compile($sr, $st, '}') || return;
            $st->{sub} .= ' })';
        }else{
            $st->{sub} .= $1;
            if($1 eq $e){
                if($mstr && $mstr ne 'm'){ #s or tr
                    if($e ne $q){
                        $$sr =~ /\G\Q$q\E/gc || return;
                        $st->{sub} .= $q;
                    }
                    $mstr = undef;
                    next;
                }
                $st->{sub} .= $1 if $$sr =~ /\G([gimosx]*[\t\n\r ]*)/gc;
                return 1;
            }
        }
    }
    return;
}

sub _compile_var {
    my($self, $sr, $st, $n) = @_;
    my $d = substr($n, 0, 1) eq '$';
    
    $st->{sub} .= '$_[0]->var('.($d ? "sub{ $n }" : "'$n'");
    while($$sr =~ /\G(?:\.([A-Za-z_][0-9A-Za-z_]*)(\()?|(\[))/gc){
        if($1){
            $st->{sub} .= ", ['.', '$1'";
            if($2){
                $self->_compile($sr, my $_st = {sub => ''}, ')') || return;
                $st->{sub} .= $_st->{var} ? ", sub{ [$_st->{sub}] }" : ", [$_st->{sub}]";
            }
        }else{
            $st->{sub} .= ", ['[', ";
            $self->_compile($sr, my $_st = {sub => ''}, ']') || return;
            return if $_st->{sub} !~ /[^\t\n\r ]/;
            $st->{sub} .= $_st->{var} ? "sub{ $_st->{sub} }" : $_st->{sub};
        }
        $st->{sub} .= ']';
        $d = 0;
    }
    return substr($st->{sub}, -20) = $n if $d;
    
    $st->{sub} .= ')';
    1;
}

sub create_directive {
    my($self, $d, $bo, $eo, $bd, $ed) = @_;
    
    my $src = substr($d->{src}, $bo, -$eo);
    $src =~ /^([\t\n\r ]*)([A-Z]+\b)?(.*?)([\t\n\r ]*)\z/s;
    $self->raise(qq{No white space after "$bd"}) if !$1;
    $self->raise(qq{No white space before "$ed"}) if !$4;
    
    my $D = $self->project->Template->Directive;
    my $n;
    if($2 && $D->can($n = ucfirst(lc $2))){
        ($src = $3) =~ s/^[\t\n\r ]+//;
    }else{
        $n = 'GET';
        $src = ($2 || '').$3;
    }
    $D->$n->new($d, \$src, $self);
}

sub create_document {
    my $self = shift;
    return $self->_create_document(@_) if ref($_[0]) eq 'SCALAR' || !$self->{CACHE_SIZE};
    my $loc = shift || die 'No location';
    
    my $path = ($loc->[0] || die 'No base dir').($loc->[1] || die 'No src');
    my $k = join('.', $path, @{$self->{MARKUP}}, $self->{STRICT}, $self->{WARNINGS});
    my $cache = $self->{cache}{$k};
    my($at, $mt);
    return ++$cache->[0] && $cache->[1] if $cache && (
        !$self->{STAT_TTL}
     || ($cache->[2] + $self->{STAT_TTL}) >= ($at = time)
     || ($cache->[2] = $at) && ($mt = (stat $path)[9]) == $cache->[3]
    );
    
    $self->reduce_cache if !$cache && keys %{$self->{cache}} >= $self->{CACHE_SIZE};
    my $doc = $self->_create_document($loc);
    $cache = $self->{cache}{$k} = [1, $doc];
    @$cache[2, 3] = ($at || time, $mt || (stat $path)[9]) if $self->{STAT_TTL};
    $doc;
}

sub _create_document {
    my $self = shift;
    my $doc = {};
    
    if(ref($_[0]) eq 'SCALAR'){
        $doc->{body} = $self->parse(shift);
    }else{
        my $loc = $doc->{location} = shift;
        my $path = ($loc->[0] || die 'No base dir').($loc->[1] || die 'No src');
        $self->OS->cat(my $s, '<', $path) || die "$!($path)";
        $doc->{body} = $self->parse(\$s, $path);
    }
    $self->{$_} && ($doc->{lc $_} = 1) for qw/STRICT WARNINGS/;
    $self->project->Template->Document->new($doc);
}

sub new {
    my $class = shift;
    bless {%{$class->CONFIG}, cache => {}, %{shift || {}}}, $class;
}

sub open {
    my $self = shift;
    $self->project->Template->new($self, $self->create_document(@_));
}

sub parse {
    my($self, $sr) = (shift, shift);
    $$sr =~ s/^[\t ]+//mg if $self->{TRIM_INDENT};
    local $self->{path} = shift;
    local $self->{body} = my $body = [];
    local $self->{stack} = [];
    local $self->{pragma} = join('', map{ $self->{uc($_)} ? '' : "no $_; " } qw/strict warnings/);
    my $m = $self->{MARKUP};
    my $reg_bgn = qr/([\t ]*)(\Q$m->[0]\E(\Q$m->[1]\E)?)/;
    my $reg_end = qr/((\Q$m->[2]\E)?\Q$m->[3]\E)([ \t]*(?:\r\n?|\n)?)/;
    my($ep, $bd, $bo, $bp) = (0); #end pos, begin directive, begin ofs, begin pos
    while(!$bd ? $$sr =~ /$reg_bgn/g : $$sr =~ /$reg_end/g){
        if(!$bd){ # [%
            ($bd, $bo) = ($2, length($1 && $3 ? $1.$2 : $2));
            $bp = pos($$sr) - $bo;
            $bp > $ep && push @$body, \(my $s = substr($$sr, $ep, $bp - $ep));
        }else{ # %]
            my $eo = length($2 && $3 ? $1.$3 : $1);
            $ep = pos($$sr) - length($1.$3) + $eo;
            my %d = (id => int @$body, src => substr($$sr, $bp, $ep - $bp));
            push @$body, $self->create_directive(\%d, $bo, $eo, $bd, $1);
            $bd = undef;
        }
    }
    $self->raise(qq{No "$m->[3]" after "$bd"}) if $bd;
    my $s = $self->{stack}[-1];
    $self->raise('No "END" directive', $s->[0]) if $s;
    push @$body, \($s = substr($$sr, $ep)) if length($$sr) > $ep;
    $body;
}

sub raise {
    my($self, $msg, $dtv) = @_;
    my $ln = !$self->{body} ? '?' : $dtv ? $dtv->ln($self->{body}) :
        $self->project->Template->Directive->_ln($self->{body});
    die $msg .= "\n at ".($dtv ? $dtv->head : '').'('.($self->{path} || '?')." $ln)\n";
}

sub reduce_cache {
    my $self = shift;
    warn 'Cache reduced from '.(int keys %{$self->{cache}}).' to '.$self->_reduce_cache(@_);
}

sub _reduce_cache {
    my $self = shift;
    my $cache = $self->{cache};
    my $cnt = keys %$cache;
    my $half = int($cnt / 2);
    my %c2k;
    while(my($k, $v) = each %$cache){
        push @{$c2k{$v->[0]} ||= []}, $k;
    }
    foreach(sort{ $a <=> $b } keys %c2k){
        delete $cache->{$_} for @{$c2k{$_}};
        last if ($cnt -= @{$c2k{$_}}) < $half;
    }
    $_->[0] = 0 for values %$cache;
    $cnt;
}

1;
