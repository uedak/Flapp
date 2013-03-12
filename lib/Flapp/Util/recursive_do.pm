package Flapp::Util::recursive_do;
use Flapp qw/-m -s -w/;
use Carp;

our %DEFAULT = (
    allow_circular => 1,
    array_ref      => undef,
    hash_ref       => undef,
    once           => 1,
    scalar         => undef,
    sort_keys      => 1,
    stop_if_false  => 0,
    unexpected_ref => undef,
    with_path      => 0,
);
our(
    $ALLOW_CIRCULAR,
    $ARRAY_REF,
    $HASH_REF,
    $ONCE,
    $SCALAR,
    $SORT_KEYS,
    $STOP_IF_FALSE,
    $UNEXPECTED_REF,
    $WITH_PATH,
);

sub array_ref {
    my $ref = shift;
    if($WITH_PATH){
        my $i = 0;
        foreach(@$ref){
            push @{$_[0]}, '['.$i++.']';
            &next($_, @_);
            pop @{$_[0]};
        }
    }else{
        &next($_) for @$ref;
    }
}

sub hash_ref {
    my $ref = shift;
    if($SORT_KEYS || $WITH_PATH){
        foreach($SORT_KEYS ? sort keys %$ref : keys %$ref){
            push @{$_[0]}, "{$_}" if $WITH_PATH;
            &next($ref->{$_}, @_);
            pop @{$_[0]} if $WITH_PATH;
        }
    }else{
        &next($_) for values %$ref;
    }
}

our $COUNT;
sub next {
    return !$SCALAR || $SCALAR->(@_) || !$STOP_IF_FALSE || goto STOP if !ref $_[0];
    my $ref = $_[0];
    return 0 if $ONCE && exists $COUNT->{$ref};
    
    if($COUNT->{$ref}++){
        croak "Circular reference: $ref" if !$ALLOW_CIRCULAR;
    }elsif(UNIVERSAL::isa($ref, 'HASH')){
        $HASH_REF ? ($HASH_REF->(\&hash_ref, @_) || !$STOP_IF_FALSE || goto STOP) : &hash_ref;
    }elsif(UNIVERSAL::isa($ref, 'ARRAY')){
        $ARRAY_REF ? ($ARRAY_REF->(\&array_ref, @_) || !$STOP_IF_FALSE || goto STOP) : &array_ref;
    }elsif($UNEXPECTED_REF){
        $UNEXPECTED_REF->(@_) || !$STOP_IF_FALSE || goto STOP;
    }else{
        croak "Unexpected reference: $ref";
    }
    $COUNT->{$ref}--;
}

sub{
    my($util, $opt) = (shift, shift);
    croak 'No options' if ref $opt ne 'HASH';
    croak
        !exists $DEFAULT{$_} ? qq{Invalid option "$_"} :
        !defined $DEFAULT{$_} && ref $opt->{$_} ne 'CODE' ? qq{Option "$_" requires code-ref} :
        next
    for keys %$opt;
    $opt = {%DEFAULT, %$opt};
    
    local $ALLOW_CIRCULAR = $opt->{allow_circular};
    local $ARRAY_REF      = $opt->{array_ref};
    local $HASH_REF       = $opt->{hash_ref};
    local $ONCE           = $opt->{once},
    local $SCALAR         = $opt->{scalar};
    local $SORT_KEYS      = $opt->{sort_keys};
    local $STOP_IF_FALSE  = $opt->{stop_if_false};
    local $UNEXPECTED_REF = $opt->{unexpected_ref};
    local $WITH_PATH      = $opt->{with_path};
    
    local $COUNT = {};
    &next($_, $WITH_PATH ? [] : ()) for @_;
    return 1;
    STOP:
    !1;
}
