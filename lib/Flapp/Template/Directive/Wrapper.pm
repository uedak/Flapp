package Flapp::Template::Directive::Wrapper;
use Flapp qw/-b Flapp::Template::Directive -s -w/;
use constant HAS_END => 1;

sub begin { shift->_begin_include(@_) }

sub end { shift->_end_block(@_) }

sub parse { shift->_parse_include(@_) }

1;
