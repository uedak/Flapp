use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use strict;
use warnings;

use X;
is int(keys %{$Flapp::G{config_path}}), 0;
{
    my $cfg = X->Config->load('development');
    is int(keys %{$Flapp::G{config_path}}), 4;
    is $cfg->foo->bar->[0]->baz, 2;
    is $cfg->{foo}{bar}[0]{baz}, 2;
    is $cfg->foo->bar->[1]->baz, 1;
    
    eval{ $cfg->Foo };
    like $@, qr/^No config\(->{Foo}\) at .*01basic\.t line \d+/;
    
    eval{ $cfg->foo->Bar };
    like $@, qr/^No config\(->{foo}{Bar}\) at .*01basic\.t line \d+/;
    
    eval{ $cfg->{foo}{bar}[0]{baz}++ };
    like $@, qr/^Modification of a read-only value attempted at .*01basic\.t line \d+/;
    
    eval{ delete $cfg->{foo}{bar}[0]{baz} };
    like $@, qr/^Modification of a read-only value attempted at .*01basic\.t line \d+/;
    
    eval{ delete $cfg->{foo} };
    like $@, qr/^Modification of a read-only value attempted at .*01basic\.t line \d+/;
    
    is $cfg->{Foo}, undef;
    ok $cfg->can('foo');
    ok !$cfg->can('Foo');
    eval{ $cfg->{Foo} = 1 };
    like $@, qr/^Modification of a read-only value attempted at .*01basic\.t line \d+/;
    
    ok !$cfg->{foo}{bar}[3];
    eval{ $cfg->{foo}{bar}[2] = 1 };
    like $@, qr/^Modification of a read-only value attempted .*01basic\.t line \d+/;
    
    eval{ $cfg->{foo}{bar}[3]{x} && 1 };
    like $@, qr/^Modification of a read-only value attempted .*01basic\.t line \d+/;
    
    eval{ push @{$cfg->{foo}{bar}}, 1 };
    like $@, qr/^Modification of a read-only value attempted .*01basic\.t line \d+/;
    
    eval{ shift @{$cfg->{foo}{bar}} };
    like $@, qr/^Modification of a read-only value attempted .*01basic\.t line \d+/;
    
    is int(keys %{$Flapp::G{config_path}}), 4;
}
is int(keys %{$Flapp::G{config_path}}), 0;



{
    my $cfg = X->Config->load('test');
    is int(keys %{$Flapp::G{config_path}}), 4;
    is $cfg->foo->bar->[0]->baz, 2;
    is $cfg->{foo}{bar}[0]{baz}, 2;
    is $cfg->foo->bar->[1]->baz, 2;
}
is int(keys %{$Flapp::G{config_path}}), 0;
