package Flapp::Template::Document;
use Flapp qw/-b Flapp::Object -m -s -w/;
__PACKAGE__->_mk_accessors_(qw/location/);

sub block {
    my($self, $dtv, $block) = @_;
    my $my = $self->{my};
    @$block{qw/begin end my/} = ($dtv->{id}, $dtv->{next_id}, {map{ $_ => 1 } keys %$my});
    if(my $bl = $block->{local}){
        foreach(keys %$bl){
            if(exists $my->{$_}){
                ($my->{$_}, $bl->{$_}) = ($bl->{$_}, $my->{$_});
            }else{
                $my->{$_} = delete $bl->{$_};
            }
        }
    }
    push @{$self->{block}}, $block;
    $dtv->{id} + 1;
}

sub block_end {
    my $self = shift;
    my $my = $self->{my};
    my $block = pop @{$self->{block}};
    if(my $bl = $block->{local}){
        $my->{$_} = $bl->{$_} for keys %$bl;
    }
    $block->{my}{$_} || delete $my->{$_} for keys %$my;
}

sub clone {
    my $self = shift;
    (ref $self)->new({%$self});
}

sub init {
    my($self, $ft) = @_;
    $self->{$_} = $ft->{$_} for qw/our stash/;
    @$self{qw/block idx my tmp/} = ([], 0, {}, {});
    $self;
}

sub loop_block {
    my $self = shift;
    my $i = $#{$self->{block}};
    my $lc = $self->project->Template->Loop;
    while($i >= 0){
        my $block = $self->{block}[$i--];
        my $lp = $self->{tmp}{$block->{begin}};
        return $block if $lp && ref $lp eq $lc;
    }
    undef;
}

sub new { bless $_[1], $_[0] }

sub path {
    my $loc = shift->{location} || return '?';
    $loc->[0].$loc->[1];
}

sub rel2abs {
    my $self = shift;
    my $r = ref $_[0] ? shift : do{ \(my $rel = shift) };
    my $src = $self->{location} && $self->{location}[1] || die qq{No base src for "$$r"};
    
    $$r =~ s%^\./%%;
    $src =~ s%/[^/]+\z%% || die;
    $src =~ s%/[^/]+\z%% || die while $$r =~ s%^\.\./%%;
    $$r = "$src/$$r";
}

my %A2Z = map{ $_ => 1 } 'A' .. 'Z';
sub var :lvalue {
    my($self, $k) = (shift, shift);
    my $set = @_ && $_[-1] eq '=' && pop;
    my $i = ($self->{strict} || $self->{warnings}) ? $k : undef;
    my $v = ref $k ? $k->($self) :
        $set ? $self->{substr($k, 0, 1) le 'Z' ? 'our' : 'my'} :
        exists $self->{my}{$k} ? $self->{my} :
        exists $self->{our}{$k} ? $self->{our} :
        exists $self->{stash}{$k} ? $self->{stash} :
        $self->{strict} ? die qq{"$k" was not declared in this scope} :
        undef;
    $v->{$k} = $self->{stash}{$k} if $set && !ref $k && !exists $v->{$k};
    $v = $set ? $v->{$k} ||= {} : $v->{$k} if @_ && !ref $k;
    
    no warnings 'numeric';
    my($hr, $ma) = (1);
    foreach my $token (@_){
        last if !$v;
        $hr = $ma = undef;
        $k = $k->($self) if ref ($k = $token->[1]);
        if($token->[0] eq '.'){
            if($ma = $token->[2] ||
                (ref $v ? (ref $v)->can($k) : $A2Z{substr($v, 0, 1)} && $v->can($k)) && []
            ){
                $ma = $ma->($self) || die if ref($ma) eq 'CODE';
                $i .= ".$k".(@$ma ? '(...)' : '()') if defined $i;
            }else{
                $v = $self->_var_not_as($i, 'HASH') if !($hr = UNIVERSAL::isa($v, 'HASH'));
                $i .= ".$k" if defined $i;
            }
        }elsif($token->[0] eq '['){
            $v = $self->_var_not_as($i, 'HASH or ARRAY')
                if !($hr = UNIVERSAL::isa($v, 'HASH')) && !UNIVERSAL::isa($v, 'ARRAY');
            $i .= '['.(defined $k ? $k : '').']' if defined $i;
        }else{
            die $self->_dump_($token);
        }
        last if $token == $_[-1];
        $v &&= $ma ? $v->$k(@$ma) :
            $hr ? ($set ? $v->{$k} ||= {} : $v->{$k}) :
            ($set ? $v->[$k] ||= {} : $v->[$k]);
    }
    no warnings 'uninitialized';
    if(!$set && defined $i && $self->{warnings}){
        $v = $v ? ($ma ? $v->$k(@$ma) : $hr ? $v->{$k} : $v->[$k]) : undef;
        warn qq{Use of undefined value: "$i"} if !defined $v;
        return $v;
    }
    $v ? ($ma ? $v->$k(@$ma) : $hr ? $v->{$k} : $v->[$k]) : undef;
}

sub _var_not_as {
    die qq{Can't use "$_[1]" as a $_[2] ref} if defined $_[1] && $_[0]->{strict};
    undef;
}

1;
