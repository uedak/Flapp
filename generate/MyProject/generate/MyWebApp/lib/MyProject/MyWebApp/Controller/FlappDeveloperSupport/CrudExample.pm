package MyProject::MyWebApp::Controller::FlappDeveloperSupport::CrudExample;
use MyProject qw/
    -b MyProject::MyWebApp::Controller
    -i Flapp::App::Web::Controller::FlappDeveloperSupport::CrudExample
    -s -w
/;

sub auto { shift->_auto(@_) } #call included auto

1;
