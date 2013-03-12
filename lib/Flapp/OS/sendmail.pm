use Flapp qw/-m -s -w/;

sub{
    my $m = shift->project->Mailer->new(@_)->filter;
    $m->send($m->sendmail_handle)
};
