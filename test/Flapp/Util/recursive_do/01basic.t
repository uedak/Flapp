use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;
use Flapp;

my $u = Flapp->Util;

is $u->recursive_do({}), 1;

my $data = sub{
    my $i = shift || 0;
    return {
        a => [$i + 1, [$i + 2, $i + 3], {i => $i + 4}],
        h => {a => [$i + 5, $i + 6], h => {i => $i + 7}, i => $i + 8},
        i => $i + 9,
    };
};

{
    is $u->recursive_do({scalar => sub{ --$_[0] }}, my $d = $data->()), 1;
    is_deeply $d, $data->(-1);
}

{ #allow_circular / once
    my $d0 = [1];
    my($d1, $d2) = ([1, $d0, undef, 2], [3, $d0, undef, 4]);
    $d1->[2] = $d2;
    $d2->[2] = $d1;
    my $opt = {scalar => sub{ $_[0]++ }};
    is $u->recursive_do($opt, $d1), 1;
    is $d0->[0], 2;
    is $d1->[0], 2;
    is $d1->[3], 3;
    is $d2->[0], 4;
    is $d2->[3], 5;
    
    $opt->{once} = 0;
    is $u->recursive_do($opt, $d1), 1;
    is $d0->[0], 4;
    is $d1->[0], 3;
    is $d1->[3], 4;
    is $d2->[0], 5;
    is $d2->[3], 6;
    
    $opt->{allow_circular} = 0;
    eval{ $u->recursive_do($opt, $d1) };
    like $@, qr/^Circular reference:/;
}

{ #array_ref / hash_ref
    is $u->recursive_do({
        array_ref => sub{
            my($next, $ar) = @_;
            push @$ar, '?';
            $next->($ar);
        },
        hash_ref => sub{
            my($next, $hr) = @_;
            $hr->{uc($_)} = delete $hr->{$_} for keys %$hr;
            $next->($hr);
        },
    }, my $d = $data->()), 1;
    is_deeply $d, {
        A => [1, [2, 3, '?'], {I => 4}, '?'],
        H => {A => [5, 6, '?'], H => {I => 7}, I => 8},
        I => 9,
    };
}

{ #stop_if_false / with_path
    my @p;
    my $opt = {
        scalar    => sub{ push(@p, '->'.join('', @{$_[1]})."=$_[0]") && --$_[0] },
        with_path => 1,
    };
    is $u->recursive_do($opt, my $d = $data->()), 1;
    is_deeply $d, $data->(-1);
    is_deeply \@p, [qw/
        ->{a}[0]=1
        ->{a}[1][0]=2
        ->{a}[1][1]=3
        ->{a}[2]{i}=4
        ->{h}{a}[0]=5
        ->{h}{a}[1]=6
        ->{h}{h}{i}=7
        ->{h}{i}=8
        ->{i}=9
    /];
    
    undef @p;
    $opt->{stop_if_false} = 1;
    is $u->recursive_do($opt, $d = $data->()), '';
    my $d2 = $data->();
    $d2->{a}[0] = 0;
    is_deeply $d, $d2;
    is_deeply \@p, [qw/
        ->{a}[0]=1
    /];
}

{ #unexpected_ref
    my $x = 'x';
    my $d = [\$x];
    eval{ $u->recursive_do({}, $d) };
    like $@, qr/^Unexpected reference: SCALAR\S+/;
    
    is $u->recursive_do({unexpected_ref => sub{ ${+shift} = 'y' }}, $d), 1;
    is $x, 'y';
}

{
    eval{ $u->recursive_do };
    like $@, qr/^No options/;
    
    eval{ $u->recursive_do({x => 1}) };
    like $@, qr/^Invalid option "x"/;
    
    eval{ $u->recursive_do({scalar => 1}) };
    like $@, qr/^Option "scalar" requires code-ref/;
}
