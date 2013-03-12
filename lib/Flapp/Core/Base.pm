package Flapp::Core::Base;
use Flapp::Core::Include;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

sub _import {
    my($self, $pkg) = (shift, shift);
    foreach(@_){
        (my $pm = "$_.pm") =~ s%::%/%g;
        require $pm;
    }
    my $isa = &Flapp::Core::Include::isa_of($pkg);
    @$isa = (@$isa, @_);
}

1;
