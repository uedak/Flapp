package MyProject::MyCmdApp::Controller;
use MyProject qw/-b MyProject::App::Cmd::Controller -s -w/;

sub auto {
    my($self, $c) = @_;
    $c->auto_options;
    1;
}

sub begin {
    my($self, $c) = @_;
    $c->begin_log;
    1;
}

sub end {
    my($self, $c) = @_;
    $c->end_log;
    1;
}

1;
