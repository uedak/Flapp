package Flapp::App::Web::Controller;
use Flapp qw/-b Flapp::Object -m -s -w/;

use constant ACTION_ARGS => {};

sub MODIFY_CODE_ATTRIBUTES {
    my($class, $code) = (shift, shift);
    my(@invalid, %arg);
    foreach(@_){
        next if !/^Action(?:\(([0-9a-z_,]+)\))?\z/ && push(@invalid, $_);
        next if !defined($1);
        $arg{$_} = 1 for split(/,/, $1);
    }
    return @invalid if @invalid;
    $class->ACTION_ARGS->{$code} = \%arg;
    return;
}

sub NAME { substr($_[0], rindex($_[0], '::Controller::') + 14) }

sub PATH {
    my $n = $_[0]->NAME;
    $n eq 'Root' ? '/' : '/'.$_[0]->Util->class2path($n).'/';
}

sub _join_ {
    my($self, $p, $d) = (shift, shift, shift);
    
    foreach(@_){
        my($k, $j, $n) = @$_;
        next if !grep{ exists $p->{$k.$_} } 1 .. $n;
        $j = '-' if !defined $j;
        
        my @v = map{ $p->{$k.$_} } 1 .. $n;
        no warnings 'uninitialized';
        $d->{$k} = (grep{ $_ ne '' } @v) ? join($j, @v) : '';
    }
    $self;
}

sub _split_ {
    my($self, $d, $p) = (shift, shift, shift);
    
    foreach(@_){
        my($k, $s, $n) = @$_;
        next if !exists $d->{$k};
        $s = '-' if !defined $s;
        
        no warnings 'uninitialized';
        @$p{map{ $k.$_ } 1 .. $n} = split(/\Q$s\E/, $d->{$k}, $n);
    }
    $self;
}

1;
