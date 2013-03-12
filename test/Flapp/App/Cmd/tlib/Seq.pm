package MyProject::MyCmdTest::Controller::Seq;
use MyProject qw/-b MyProject::MyCmdTest::Controller -s -w/;

sub auto {
    my($self, $c) = @_;
    $c->mail_from('from@test.com');
    $c->mailto_on_die('die@test.com');
    $c->mailto_on_success('success@test.com');
    $c->mailto_on_warn('warn@test.com');
    1;
}

sub seq1 :Action {
    my($self, $c) = @_;
    $c->dispatch("Seq::$_") for qw/run1 run2 run3/;
}

sub seq2 :Action {
    my($self, $c) = @_;
    $c->dispatch("Seq::$_", {fork => 1}) for qw/run1 run2 run3/;
}

sub run1 :Action {
    my($self, $c) = @_;
}

sub run2 :Action {
    my($self, $c) = @_;
    if($c->args->{FORK} && fork){
        wait;
    }else{
        warn '?' if $c->args->{WARN};
        die '!' if $c->args->{DIE};
        exit if $c->args->{FORK};
    }
}

sub run3 :Action {
    my($self, $c) = @_;
}

1;
