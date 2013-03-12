package Flapp::Template::Directive::Include;
use Flapp qw/-b Flapp::Template::Directive -s -w/;

sub begin { shift->_begin_include(@_) }

sub parse { shift->_parse_include(@_) }

1;
