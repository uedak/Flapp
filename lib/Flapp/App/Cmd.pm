package Flapp::App::Cmd;
use Flapp qw/-b Flapp::App -m -r -s -w/;
use constant OPTIONS => [qw/
    mail_from
    mailto_on_die
    mailto_on_success
    mailto_on_warn
    parallel_run
/];
our $C;
our %CD = (
    '+' => [1, undef],
    '#' => [1, undef],
    '*' => [1, 'successfully'],
    '?' => [2, 'with warning'],
    '!' => [2, 'with die'],
);
our $PID = $$;
__PACKAGE__->_mk_accessors_(qw/args argv/);
__PACKAGE__->mk_route_accessors(@{__PACKAGE__->OPTIONS});

sub PID { $PID }

sub auto_options {
    my $c = shift;
    my $cfg = $c->app_config;
    $c->$_($cfg->{$_}) for @{$c->OPTIONS};
}

sub begin_log {
    my $c = shift;
    $c->route->{log_offset} = (-s $c->logger->path || 0);
    $c->_log('*', $c->path.' BEGIN');
}

sub default_config { shift->project->config->App->Cmd }

sub dispatch {
    my($c, $path, $opt) = (shift, shift, {%{shift || {}}});
    local $C = $c if !$C;
    !defined $opt->{$_} && ($opt->{$_} = 1) for qw/begin auto end/;
    my $r = {};
    $r->{action} = $path =~ s/(?:^|::)([a-z][0-9a-z_]*)\z// ? $1 : 'index';
    $r->{controller} = $path ne '' ? $path : 'Root';
    
    local $c->{route} = $r if $c->{route};
    $c->{route} = $r;
    my $ctl = $c->controller || die qq{No controller for "$r->{controller}"};
    my $code = $ctl->can($r->{action}) || die qq{No action "$r->{action}" via $ctl};
    $code && $ctl->ACTION_ARGS->{$code} || die qq{No ":Action" for $ctl->$r->{action}};
    $c->_dispatch($r, $opt);
}

sub __dispatch {
    my($c, $r, $opt) = @_;
    
    if(!$c->mail_from && grep{ defined($c->$_) && /^mailto/ } @{$c->OPTIONS}){
        die 'No $c->mail_from';
    }
    
    $c->OS->mkdir_p($c->pid_dir) if !-d $c->pid_dir;
    if((my $n = $c->num_of_para + 1) > 1){
        my $max = $c->parallel_run || die 'Parallel run not allowed';
        $c->on_parallel_run($n, $max) if $n > $max;
    }
    
    my $f = $c->pid_file;
    $c->OS->cat('', '>', $f) || die "$!($f)";
    eval{ $opt->{fork} && fork ? wait : shift->SUPER::__dispatch(@_) };
    my $msg = $@;
    $msg = $1 if $msg && $msg =~ /^(.+)\0/;
    $c->_log('!', $msg) if $msg;
    $msg ? exit 255 : exit if $$ != $PID;
    $c->OS->unlink($f);
}

sub end_log {
    my($c, $finalize) = @_;
    my $r = $c->route;
    return !1 if !defined $r->{log_offset};
    
    my $log = $c->logger->path;
    $c->OS->open(my $H, $log) || die "$!($log)";
    seek $H, $r->{log_offset}, 0;
    my $reg = qr/^\[([*+#?!])\] [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} $PID\b/;
    $r->{mail_body} = '';
    while(my $ln = <$H>){
        $ln =~ $reg || next;
        $r->{mail_body} .= $ln if $1 ne '+';
        $r->{warn} ||= ($1 eq '?');
        $r->{die}  ||= ($1 eq '!');
    }
    my $cd = $r->{die} ? '!' : $r->{warn} ? '?' : '*';
    my $msg = $c->path.' END '.$CD{$cd}->[1];
    die $msg."\0" if $r->{die} && !$finalize;
    $c->_log($cd, $msg);
    $r->{mail_subject} = "[$cd] ".$c->project." $msg";
    while(my $ln = <$H>){
        $ln =~ $reg && ($r->{mail_body} .= $ln) && last;
    }
    close($H);
    (print "\n") && $c->logger->print("\n");
}

sub finalize {
    my($c, $msg) = @_;
    my $r = $c->route;
    if($msg){
        $c->_log('!', $msg) if $msg !~ /^.+\0/;
        $c->end_log(1);
    };
    my $from = $c->mail_from;
    my $to = $r->{die} ? $c->mailto_on_die : $r->{warn} ? $c->mailto_on_warn :
        $c->mailto_on_success;
    $c->OS->sendmail(\<<_END_) if $from && $to;
From: $from
To: $to
Subject: $r->{mail_subject}

$r->{mail_body}
_END_
}

sub log { shift->_log('+', @_) }

sub _log {
    my($c, $cd, $msg) = (shift, shift, shift);
    my $out = ($CD{$cd} || die qq{Invalid cd "$cd"})->[0] == 2 ? *STDERR : *STDOUT;
    print $out "[$cd] $msg\n";
    if(!defined($c->route->{log_offset})){
        print $out " - $_\n" for @_;
        return !1;
    }
    
    my $lgr = $c->logger;
    my $now = $lgr->now;
    my $pid = $PID;
    $pid .= "->$$" if $$ != $pid;
    $msg =~ s/\n/\\n/g;
    $lgr->print("[$cd] ".$now->ymd.' '.$now->hms." $pid $msg\n");
    foreach(@_){
        print $out " - $_\n";
        (my $v = $_) =~ s/\n/\\n/g;
        $lgr->print(" - $v\n");
    }
    1;
}

sub log_comment { shift->_log('#', @_) }

sub logger { $C->{logger} ||= do{
    (my $n = $C->app_name.'-'.$C->path) =~ s/::/-/g;
    $n =~ s/-index\z//;
    $C->project->Logger->new($n);
} }

sub mk_route_accessors {
    my $class = shift;
    foreach(@_){
        my $k = $_;
        my $code = sub{
            return $_[0]->route->{$k} if @_ == 1;
            $_[0]->route->{$k} = $_[1];
            $_[0];
        };
        no strict 'refs';
        *{$class."::$_"} = $code;
    }
}

sub new {
    my $c = shift->_new_({});
    $c->{argv} = [@_];
    $c->{args} = {};
    while(my $argv = shift){
        if($argv =~ /^-([0-9A-Za-z_]+)\z/){
            my @o = split(//, "$1");
            $c->{args}{"-$_"} = [] for @o;
            $argv = $c->{args}{"-$o[-1]"};
        }elsif($argv =~ /^(--.+)\z/){
            $argv = $c->{args}{$1} = [];
        }else{
            $c->{args}{$1} = $2 if $argv =~ /^([0-9A-Za-z_]+)=(.+)\z/;
            next;
        }
        push @$argv, shift while @_ && $_[0] !~ /^-|=/;
    }
    $c;
}

sub num_of_para {
    my $c = shift;
    my $n = 0;
    $c->OS->opendir(my $D, $c->pid_dir) || die "$!(".$c->pid_dir.')';
    while(my $f = readdir($D)){
        next if substr($f, 0, 1) eq '.';
        $n++;
    }
    closedir($D);
    $n;
}

sub on_parallel_run {
    my($c, $n, $max) = @_;
    die "Number of processes($n) exceeded parallel_run($max)";
}

sub path {
    my $c = shift;
    $c->controller->NAME.'::'.$c->action;
}

sub pid_dir {
    my $c = shift;
    (my $path = $c->path) =~ s%::%/%g;
    $c->app_root_tmp('pids')."/$path";
}

sub pid_file {
    my $c = shift;
    $c->pid_dir.'/'.$c->project->hostname.'_'.$PID;
}

sub project_options { {trace => {
    exclude => qr/^Flapp::App/,
    warn => sub{
        (my $msg = shift) =~ s%^ at \(eval\)\(Flapp/App/Cmd\.pm [0-9]+\)\n%%mg;
        $C->warn_without_trace($msg);
    },
}} }

sub run {
    my($class, $path) = (shift, shift);
    $path = '' if !defined $path;
    $C = $class->new(@_);
    my $proj = $class->project;
    $proj->begin($class->project_options);
    local $::SIG{INT} = sub{ die 'SIG(INT)' };
    local $::SIG{TERM} = sub{ die 'SIG(TERM)' };
    local $::SIG{PIPE} = sub{ die 'SIG(PIPE)' };
    my($msg1, $msg2);
    eval{ $C->dispatch($path) };
    eval{ $proj->logger->write('__DIE__', $class->app_name, $msg1) } || die $msg1 if ($msg1 = $@);
    eval{ $C->finalize($msg1) };
    eval{ $proj->logger->write('__DIE__', $class->app_name, $msg2) } || die $msg2 if ($msg2 = $@);
    exit 255 if $msg1 || $msg2;
}

sub warn_without_trace { shift->_log('?', @_) }

1;
