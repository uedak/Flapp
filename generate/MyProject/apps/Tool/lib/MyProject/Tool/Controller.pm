package MyProject::Tool::Controller;
use MyProject qw/-b MyProject::App::Cmd::Controller -s -w/;

sub begin { 1 } #nolog

sub auto { 1 } #nomail

sub end { 1 } #nolog

1;
