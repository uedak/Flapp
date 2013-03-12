package Flapp::Core::Strict;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

sub _import { shift; goto \&strict::import }

1;
