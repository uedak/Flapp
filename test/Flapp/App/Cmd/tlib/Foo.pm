package MyProject::MyCmdTest::Controller::Foo;
use MyProject qw/-b MyProject::MyCmdTest::Controller -s -w/;

sub index :Action {
    print "index\n";
}

sub foo :Action {
    print "foo\n";
}

1;
