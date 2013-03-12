package Flapp::Core::Module;
use Filter::Util::Call;
use Flapp;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

sub _import {
    my($self, $pkg) = (shift, shift);
    Filter::Util::Call::real_import(bless(\(my $f = 0), __PACKAGE__), $pkg, 0);
}

sub filter {
    ${$_[0]} ||= $Flapp::G{module}->{(caller(1))[6]} = 1;
    my $st = filter_read();
    s/->[\t\n\r ]*SUPER::([0-9A-Za-z_]+)([\t\n\r ]*\()?/
        "->Flapp::Core::Include::SUPER('$1'".($2 ? ',' : ')')/eg if $st > 0;
    $st;
}

1;
