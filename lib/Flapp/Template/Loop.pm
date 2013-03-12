package Flapp::Template::Loop;
use Flapp qw/-b Flapp::Object -m -s -w/;

sub count { $_[0]->[0] + 1 }

sub even { !!($_[0]->[0] % 2) }

sub first { !$_[0]->[0] }

sub index { $_[0]->[0] }

sub last { $_[0]->[0] == $#{$_[0]->[1] || die} }

sub max { $#{$_[0]->[1] || die} }

sub next { ($_[0]->[1] || die)->[$_[0]->[0] + 1] }

sub odd { !($_[0]->[0] % 2) }

sub parity { !($_[0]->[0] % 2) ? 'odd' : 'even' }

sub prev { $_[0]->[0] > 0 && ($_[0]->[1] || die)->[$_[0]->[0] - 1] }

sub size { int @{$_[0]->[1] || die} }

1;
