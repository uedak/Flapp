package MyProject::MyCmdTest::Controller::Bar::Baz;
use MyProject qw/-b MyProject::MyCmdTest::Controller -s -w/;

sub index :Action {
    print "index\n";
}

sub baz :Action {
    print "baz\n";
}

1;
