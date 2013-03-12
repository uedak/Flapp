package Flapp::Core::Require;
use Carp;
use Flapp;
use strict;
use warnings;

sub import { shift->_import(scalar caller, @_) }

our $VOID;
sub _import {
    my($self, $pkg) = (shift, shift);
    (my $path = $pkg) =~ s%::%/%g;
    my $dir = substr($::INC{"$path.pm"}, 0, -3); #.pm
    opendir(D, $dir) || croak "$!($dir)";
    while(my $f = readdir(D)){
        $f =~ /^(([A-Z]?)[0-9A-Za-z_]*)\.pm\z/ || next;
        my $pm = "$path/$1.pm";
        my $sub = $pkg.'::'.$1;
        my $code = $2 ? sub{
            if(!$::INC{$pm} && !eval{ require $pm }){
                delete $::INC{$pm};
                croak $@;
            }
            $sub;
        } : sub{
            my $code = $Flapp::G{require}->{$sub} ||= do{
                my $r = eval "package $pkg; require \$pm" || do{
                    delete $::INC{$pm};
                    croak $@;
                };
                croak "$pm did not return a code ref" if ref($r) ne 'CODE';
                if($Flapp::G{module}->{"$path.pm"} && !$Flapp::G{module}->{$pm}){
                    croak qq{Can't require non-module "$pm" from module "$path.pm"};
                }
                $r;
            };
            $VOID ? $code : goto $code;
        };
        no strict 'refs';
        *$sub = $code;
    }
    closedir(D);
}

1;
