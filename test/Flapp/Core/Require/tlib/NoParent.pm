package NoParent;
use Flapp qw/-m -s -w/;

sub foo {
    shift->SUPER::foo(@_);
}

1;
