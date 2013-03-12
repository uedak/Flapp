package MyProject::MyWebApp::Controller::FlappDeveloperSupport::CrudExample2;
use MyProject qw/
    -b MyProject::MyWebApp::Controller
    -i Flapp::App::Web::Controller::FlappDeveloperSupport::CrudExample
    -i Flapp::App::Web::Controller::FlappDeveloperSupport::CrudExample2
    -s -w
/;

sub auto { shift->_auto(@_) } #call included auto

1;
