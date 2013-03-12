package Flapp::App::Web::Session::State;
use Flapp qw/-b Flapp::Object -m -r -s -w/;

sub finalize {}

sub load_sid {}

sub load_sid_from_query {}

sub new { shift->_new_({%{+shift}}) }

1;
