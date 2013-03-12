package Flapp::Core;
use Flapp::Core::Require;
use Flapp::Core::Strict;
use Flapp::Core::Warnings;
use Carp;
use constant IMPORT => {qw/-b Base -i Include -m Module -r Require -s Strict -w Warnings/};

sub import { shift->_import(scalar caller, @_) }

sub _import {
    my($self, $pkg) = (shift, shift);
    my($i, @i);
    foreach(@_){
        if(/^-/){
            $i->_import($pkg, @i) if $i;
            undef @i;
            $i = $self->IMPORT->{$_} || croak qq{Invalid option: "$_"};
            $i = $self->$i;
        }else{
            croak qq{No option for "$_"} if !$i;
            push @i, $_;
        }
    }
    $i->_import($pkg, @i) if $i;
}

1;
