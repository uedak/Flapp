package Flapp::Core::Warnings;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

sub _import { shift; goto \&warnings::import }

1;
