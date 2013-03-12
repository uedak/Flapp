use Flapp qw/-m -s -w/;
use Digest::MD5;

sub {
    my $c = shift;
    my $sid = $c->session->ensure_id;
    $c->{csrf_token}{$sid} ||= Digest::MD5::md5_hex($sid);
};
