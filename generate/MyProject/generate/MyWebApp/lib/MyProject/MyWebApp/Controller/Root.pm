package MyProject::MyWebApp::Controller::Root;
use MyProject qw/-b MyProject::MyWebApp::Controller -s -w/;

sub index :Action {
    my($self, $c) = @_;
}

1;
