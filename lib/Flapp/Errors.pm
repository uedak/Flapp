package Flapp::Errors;
use Flapp qw/-b Flapp::Object -m -s -w/;
use Flapp::Core::Include;
use constant WHITESPACE => {
    "\t" => 'タブ文字',
    "\n" => '改行',
    "\r" => '改行',
    ' '  => '半角スペース',
    '　' => '全角スペース',
};

__PACKAGE__->_mk_accessors_(qw/label/);
__PACKAGE__->define_errors(
    101 => '%s は使用できません',
    102 => '正しい日付を入力して下さい',
    103 => '正しいメールアドレスを入力して下さい',
    104 => '%s は選択できません',
    105 => '正しい時刻を入力して下さい',
    106 => '整数を入力して下さい',
    107 => '入力されていません',
    108 => '数値を入力して下さい',
    109 => '%s 以上の値を入力して下さい',
    110 => '%s 以下の値を入力して下さい',
    111 => '選択されていません',
    112 => '%s 文字で入力して下さい',
    113 => '%s 文字以上で入力して下さい',
    114 => '%s 文字以内で入力して下さい',
    115 => '正しい番号を入力して下さい',
    116 => '正しい日時を入力して下さい',
    117 => '正しいURLを入力して下さい',
    118 => '正しい郵便番号を入力して下さい',
    199 => '他のユーザーに更新されたため、情報を保存できません',
);

sub ERRORS {
    my $class = shift->_class_;
    my $e = $class->_global_->{ERRORS} ||= do{
        &Flapp::Core::Include::isa_of($class, my $i = []);
        @$i ? {%{$i->[-1]->ERRORS}} : {};
    };
    @_ ? $e->{$_[0]} || die qq{No error for code "$_[0]"} : $e;
}

sub TO_JSON {
    my $self = shift;
    {messages => $self->messages, details => $self->details};
}

sub add {
    warn "Numbers($_[1]) shouldn't be used for name" if defined $_[1] && $_[1] =~ /^[0-9]+\z/;
    return shift if @_ <= 2;
    my($self, $n) = (shift, shift);
    my $er;
    
    $_->[0] eq $n && ($er = $_) && last for @{$self->{errors}};
    push(@{$self->{errors}}, $er = [$n]) if !$er;
    
    E: foreach(@_){
        my $ref = ref $_;
        my %e;
        if(!$ref){
            @e{qw/cd msg/} = ($_, $self->ERRORS($_));
        }elsif($ref eq 'ARRAY'){
            my($cd, @s) = @$_;
            @e{qw/cd msg/} = ($cd, sprintf($self->ERRORS($cd), @s));
        }elsif($ref eq 'HASH'){
            %e = %$_;
        }elsif($ref eq ref $self){ #nested
            push @{$er->[2] ||= []}, $_;
            next;
        }else{
            die "Invalid ref($ref)";
        }
        $_->{msg} eq $e{msg} && next E for @{$er->[1]};
        push @{$er->[1] ||= []}, \%e;
    }
    $self;
}

sub clear {
    my $self = shift;
    undef @{$self->{errors}};
    $self;
}

sub count {
    my $self = shift;
    my $cnt = 0;
    foreach my $er (@{$self->{errors}}){
        $cnt += @{$er->[1]} if $er->[1];
        next if !$er->[2];
        $cnt += $_->count for @{$er->[2]};
    }
    $cnt;
}

sub define_errors {
    my $class = shift;
    my $e = $class->ERRORS;
    while(my $cd = shift){
        die qq{Duplicate error code "$cd"} if exists $e->{$cd};
        $e->{$cd} = shift;
    }
    $class;
}

sub details {
    my $self = shift;
    my $l = $self->{label};
    my @d;
    
    foreach my $er (@{$self->{errors}}){
        my $cd;
        if($er->[2]){
            my @d;
            foreach(@{$er->[2]}){
                my $d = $_->details;
                push @d, @$d ? $d : undef;
                $cd = \@d if @$d;
            }
        }
        next if !$er->[1] && !$cd;
        push @d, my $d = {name => $er->[0]};
        $d->{label} = $l->{$er->[0]} if $l && defined $l->{$er->[0]};
        $d->{errors} = $er->[1] if $er->[1];
        $d->{children} = $cd if $cd;
    }
    \@d;
}

sub _found_invalid_characters { #From Validator::chr
    my($self, $chrs) = @_;
    my @chr = map{ $self->WHITESPACE->{$_} || "「$_」" } @$chrs;
    @chr = (@chr[0, 1, 2], '...') if @chr > 3;
    [101, join(', ', @chr)];
}

sub get {
    my $self = shift;
    my $e;
    $_->[0] eq $_[0] && ($e = $_) && last for @{$self->{errors}};
    $e ? (@_ == 2 ? ($e->[2] && $e->[2][$_[1]]) : $e->[1]) : undef;
}

sub has_error {
    my $e = shift->get(shift) || return !1;
    my $cd = shift;
    $_->{cd} eq $cd && return 1 for @$e;
    !1;
}

sub is_empty {
    my $self = shift;
    my @c;
    $_->[1] ? return !1 : push @c, $_->[2] for @{$self->{errors}};
    foreach(@c){
        $_->is_empty || return !1 for @$_;
    }
    1;
}

sub merge {
    my($e1, $e2) = @_;
    
    my %e1 = map{ $_->[0] => $_->[2] } @{$e1->{errors}};
    $_->[2] && $e1{$_->[0]} && die qq{Can't merge nested errors on $_->[0]"} for @{$e2->{errors}};
    
    if((my $l1 = $e1->{label}) && (my $l2 = $e2->{label})){
        die qq{Label mismatch "$l1->{$_}" ne "$l2->{$_}" for "$_"} for
            grep{ exists $l2->{$_} && $l1->{$_} ne $l2->{$_} } keys %$l1;
        $e1->{label} = {%$l1, %$l2};
    }
    foreach(@{$e2->{errors}}){
        $e1->add($_->[0], @{$_->[1]}) if $_->[1];
        $e1->add($_->[0], @{$_->[2]}) if $_->[2];
    }
    $e1;
}

sub messages { shift->_messages([], '') }
*to_array = \&messages;

sub _messages {
    my($self, $m, $pfx) = @_;
    my $l = $self->{label};
    
    foreach my $er (@{$self->{errors}}){
        my $n = $er->[0];
        if($n eq ''){
            $n = $pfx;
        }else{
            $n = $l->{$n} if $l && exists $l->{$n};
            $n = "$pfx $n" if $pfx ne '';
        }
        my $pfx = $n;
        $n = "[$n] " if $n ne '';
        push @$m, map{ $n.$_->{msg} } @{$er->[1]} if $er->[1];
        next if !$er->[2];
        my $i = $pfx ne '' && @{$er->[2]} > 1 && 1;
        $_->_messages($m, $pfx.($i && '('.$i++.')')) for @{$er->[2]};
    }
    $m;
}

sub names {
    my($self) = @_;
    my @n;
    N: foreach my $er (@{$self->{errors}}){
        if($er->[1]){
            push @n, $er->[0];
        }elsif($er->[2]){
            !$_->is_empty && (push @n, $er->[0]) && next N for @{$er->[2]};
        }
    }
    \@n;
}

sub new { shift->_new_({errors => []}) }

1;
