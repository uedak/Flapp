package MyProject::MyCmdTest::Controller::Mail;
use MyProject qw/-b MyProject::MyCmdTest::Controller -s -w/;

sub auto {
    my($self, $c) = @_;
    $c->mail_from('from@test.com') if $c->action ne 'no_from';
    $c->mailto_on_die('die@test.com');
    $c->mailto_on_success('success@test.com');
    $c->mailto_on_warn('warn@test.com');
    #$c->parallel_run(1);
    1;
}

sub mailtest :Action {
    my($self, $c) = @_;
    
    $c->log('ok1');
    warn 'ほげ' if $c->args->{warn};
    $c->log('ok2');
    die 'ふが' if $c->args->{die};
    $c->log('ok3');
}

sub no_from :Action {
    my($self, $c) = @_;
    
    $c->log('ok1');
    warn 'ほげ' if $c->args->{warn};
    $c->log('ok2');
    die 'ふが' if $c->args->{die};
    $c->log('ok3');
}

1;
