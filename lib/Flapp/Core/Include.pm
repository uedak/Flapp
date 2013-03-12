package Flapp::Core::Include;
use Carp;
use Flapp;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

sub _import {
    my($self, $pkg) = (shift, shift);
    
    foreach(@_){
        (my $pm = "$_.pm") =~ s%::%/%g;
        require $pm;
        
        my @pkg = ($_);
        if(@{&isa_of($_, \@pkg)} && !$Flapp::G{module}->{$pm}){
            die qq{Can't include package "$_" (having \@ISA and non-module)};
        }
        
        foreach(@pkg){
            my $as = $_.'::As::'.$pkg;
            no strict 'refs';
            foreach my $sub (keys %{$_.'::'}){
                my $code = *{$_.'::'.$sub}{CODE} || next;
                *{$as.'::'.$sub} = $code;
            }
            @{$as.'::ISA'} = @{$pkg.'::ISA'};
            @{$pkg.'::ISA'} = ($as);
            use strict 'refs';
            $_->INCLUDED($pkg) if $_->can('INCLUDED');
        }
    }
}

sub isa_of {
    my($pkg, $inc) = @_;
    no strict 'refs';
    my $isa = \@{$pkg.'::ISA'};
    while(@$isa == 1 && $isa->[0] =~ /^(.+)::As::\Q$pkg\E\z/){
        unshift @$inc, $1 if $inc;
        $isa = \@{$isa->[0].'::ISA'};
    }
    $isa;
}

sub SUPER {
    my($self, $sub) = (shift, shift);
    my $pkg = caller;
    my $as = $pkg.'::As::'.(ref $self || $self);
    $pkg = $as if $as->can($sub);
    my $code;
    ($code = $_->can($sub)) && last for do{ no strict 'refs'; @{$pkg.'::ISA'} };
    croak qq{Can't locate object method "$sub" via package "$pkg"} if !$code;
    unshift @_, $self;
    goto $code;
}

1;
