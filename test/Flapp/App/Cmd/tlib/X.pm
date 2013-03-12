package MyProject::MyCmdTest::Controller::X;
use MyProject qw/-b MyProject::MyCmdTest::Controller -s -w/;

sub args :Action {
    my($self, $c) = @_;
    $c->log($c->dump($c->args));
    $c->log($c->dump($c->argv));
}

sub dietest1 :Action {
    my($self, $c) = @_;
    
    $c->log("あ");
    warn "あ";
    die "あ";
}

sub dietest2 :Action {
    my($self, $c) = @_;
    
    $c->log("あ\n");
    warn "あ\n";
    die "あ\n";
}

sub logtest :Action {
    my($self, $c) = @_;
    
    $c->log("あ");
    $c->log("\nあ");
    $c->log("\nあ\n");
    $c->log("\n");
    
    $c->log("あ","あ");
    $c->log("\nあ","\nあ");
    $c->log("\nあ\n","\nあ\n");
    $c->log("\n","\n");
}

sub warntest :Action {
    my($self, $c) = @_;
    $c->log("あ");
    warn "あ";
    $c->log("\nあ");
    warn "\nあ";
    $c->log("\nあ\n");
    warn "\nあ\n";
    $c->log("\n");
    warn "\n";
}

1;
