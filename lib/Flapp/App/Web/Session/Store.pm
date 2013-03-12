package Flapp::App::Web::Session::Store;
use Flapp qw/-b Flapp::Object -m -r -s -w/;

sub cleanup {}

sub finalize {}

sub load {}

sub new { shift->_new_({%{+shift}}) }

1;
