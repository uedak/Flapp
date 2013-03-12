package MyProject::MyWebApp::Controller::FlappDeveloperSupport;
use MyProject qw/
    -b MyProject::MyWebApp::Controller
    -i Flapp::App::Web::Controller::FlappDeveloperSupport
    -s -w
/;

sub auto {
    my($self, $c) = @_;
    $c->debug || $c->http_error(404);
}

1;
