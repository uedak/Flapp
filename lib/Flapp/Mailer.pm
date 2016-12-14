package Flapp::Mailer;
use Flapp qw/-b Flapp::Object -m -s -w/;
use Encode;
use IO::Handle;
use constant ADDR => {
    To   => 1,
    Cc   => 1,
    Bcc  => 1,
    From => 0,
    'Return-Path' => 0,
    'Reply-To'    => 0,
};
use constant SMTP => 'Flapp::Mailer::SMTP';

sub attachment {
    my($self, $att) = @_;
    $self->{attachment} = {};
    foreach(keys %$att){
        my $m = $self->Util->mime_type($_) || die qq{Can't get myme-type: "$_"};
        $self->{attachment}{$_} = [$att->{$_}, $m];
    }
    $self;
}

sub config { shift->project->config->Mailer }

sub filter {
    my $self = shift;
    my $fs = shift || $self->config->filter || return $self;
    my $h = $self->{header};
    my $org;
    foreach my $k (sort grep{ exists $self->ADDR->{$_} } keys %$h){
        my(@addr, %addr, $filtered);
        foreach(split /[\t\n\r ]*,+[\t\n\r ]*/, $h->{$k}){
            my $addr = /<(.+)>/ ? $1 : $_;
            my $f;
            (ref $_->[0] ? ($addr =~ $_->[0]) : ($_->[0] eq '*' || $addr eq $_->[0]))
             && ($f = $_) && last for @$fs;
            die 'Invalid filter: '.$self->dump($fs) if !$f;
            if($f->[1] eq '*' || grep{ $_ eq $addr } my @f = split(/ *,+ */, $f->[1])){
                $addr{$addr}++;
                push @addr, $_;
            }else{
                $filtered = 1;
                !$addr{$_}++ && push @addr, $_ for @f;
            }
        }
        next if !$filtered;
        $org .= "$k: $h->{$k}\n";
        $h->{$k} = $self->ADDR->{$k} ? join(', ', @addr) : $addr[0];
    }
    ${$self->{body}} .= "\n==== original header ====\n$org" if $org;
    $self;
}

sub jis_encode {
    my $self = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $self->Util->tr($r, 'utf8_tilde');
    Encode::_utf8_on($$r);
    $$r = Encode::encode('iso-2022-jp', $$r);
}

sub mime_encode {
    my $self = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $self->Util->tr($r, 'utf8_tilde');
    Encode::_utf8_on($$r);
    $$r = Encode::encode('MIME-Header-ISO_2022_JP', $$r);
}

sub new {
    my $self = shift->_new_({});
    my $r = $self->{body} = ref $_[0] ? shift : do{ \(my $s = shift) };
    $self->attachment(@_) if @_;
    
    my $h = $self->{header} = {};
    my $pos;
    while($$r =~ /\G([0-9a-zA-Z-]+)[ \t]*:[ \t]*(.*)\n(\n)?/g){
        $pos = $3 && pos $$r;
        my $v = $2;
        (my $k = lc($1)) =~ s/(^.|\-.)/uc($1)/eg; #Camel
        $h->{$k} = $v;
        last if $pos;
    }
    die 'Parse error' if !$pos;
    die 'No To:' if !$h->{To};
    substr($$r, 0, $pos) = '';
    -r $_ || die "$!($_)" for keys %{$self->{attachment} || {}};
    $h->{'MIME-Version'} ||= '1.0';
    $self;
}

sub recipient {
    my $self = shift;
    my $h = $self->{header};
    my %r;
    foreach my $k (sort grep{ $self->ADDR->{$_} } keys %$h){
        $r{/<(.+)>/ ? $1 : $_}++ for split /[\t\n\r ]*,+[\t\n\r ]*/, $h->{$k};
    }
    sort keys %r;
}

sub send {
    my($self, $H) = @_;
    my $h = $self->{header};
    $self->jis_encode(\(my $body = ${$self->{body}}));
    
    $H->print("$_: ".$self->mime_encode($h->{$_})."\n") for sort keys %$h;
    my $boundary;
    if($self->{attachment}){
        while(1){
            $boundary = '----=_NextPart_'.rand;
            last if index($body, $boundary) < 0;
        }
        $H->print(qq{Content-Type: multipart/mixed; boundary="$boundary"\n\n});
        $H->print("This is a multi-part message in MIME format.\n\n");
        $H->print("--$boundary\n");
    }
    $H->print(qq{Content-Type: text/plain; charset="iso-2022-jp"\n});
    $H->print("Content-Transfer-Encoding: 7bit\n\n");
    $H->print($body);
    if($self->{attachment}){
        $H->print("\n");
        require MIME::Base64;
        foreach my $path (sort keys %{$self->{attachment}}){
            my $att = $self->{attachment}{$path};
            my $fn = $self->mime_encode($att->[0]);
            $H->print("\n--$boundary\n");
            $H->print("Content-Type: $att->[1]\n");
            $H->print(qq{Content-Disposition: attachment; filename="$fn"\n});
            $H->print("Content-Transfer-Encoding: base64\n\n");
            $self->OS->cat(my $buf, '<:raw', $path) || die "$!($path)";
            $H->print(MIME::Base64::encode_base64($buf));
        }
        $H->print("\n--$boundary--\n");
    }
    $H->close;
}

sub sender {
    my $self = shift;
    my $h = $self->{header};
    my $addr = $h->{'Return-Path'} || $h->{From} || die 'No sender';
    $addr =~ /<(.+)>/ ? $1 : $addr;
}

sub sendmail_handle {
    my $self = shift;
    my $os = $self->OS;
    my $s = $self->sender;
    die "Invalid address($s)" if !$os->is_eml($s);
    my $H;
    
    if(my $dir = $self->spool_dir){
        my $f = $self->spool_file($dir);
        $os->open($H, '>', $f) || die "$!($f)";
    }elsif(my $cmd = $self->config->{sendmail}){
        $os->open($H, '| %path -t -f %eml', $cmd, $s) || die "$!($cmd, $s)";
    }elsif(my $rel = $self->config->{smtp}){
        $H = $self->SMTP->open($rel, $self);
    }else{
        die 'No config';
    }
    
    $H;
}

sub spool_dir { $Flapp::MAIL_SPOOL_DIR || shift->config->{spool_dir} }

sub spool_file {
    my($self, $dir) = @_;
    
    -w $dir || die "$!($dir)";
    my $pfx = $self->project->now->strftime('%Y%m%d_%H%M%S');
    my $i = 1;
    my $f;
    while(-f ($f = sprintf('%s/%s_%05d.eml', $dir, $pfx, $i))){
        die 'overflow' if ++$i >= 99999
    }
    $f;
}

package Flapp::Mailer::SMTP;
use Flapp qw/-b Flapp::Object -s -w/;

sub close {
    my $smtp = $_[0]->[0];
    $smtp->dataend && $smtp->quit || die $smtp->message;
}

sub open {
    require Net::SMTP;
    my($class, $rel, $m) = @_;
    my $smtp = Net::SMTP->new(@$rel) || die 'Net::SMTP failed: '.$m->dump($rel);
    $smtp->mail($m->sender) || die $smtp->message;
    $smtp->recipient($m->recipient) || die $smtp->message;
    $smtp->data || die $smtp->message;
    $class->_new_([$smtp]);
}

sub print { shift->[0]->datasend(@_) }

1;
