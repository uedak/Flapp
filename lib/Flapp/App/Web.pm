package Flapp::App::Web;
use Flapp qw/-b Flapp::App -m -r -s -w/;
use Symbol;
use constant DEFAULT_VIEW_EXT => 'ft';
use constant ROUTING => [
    ['/'                        => {controller => 'Root', action => 'index'}],
    ['/:action'                 => {controller => 'Root'}],
    ['/:controller/'            => {action => 'index'}],
    ['/:controller/:action'     => {}],
    ['/:controller/:action/:id' => {}],
];
use constant ROUTING_ARGS => {
    controller => qr%(?:[a-z][0-9a-z_]*/)*[a-z][0-9a-z_]*%,
    action     => qr/[a-z][0-9a-z_]*/,
    id         => qr/[0-9]+/,
};
use constant SESSION_EXPIRE => 60 * 60 * 24;
use constant STR2HTM => {
    "\n"   => '<br />',
    "\r"   => '<br />',
    "\r\n" => '<br />',
    '"'    => '&quot;',
    '&'    => '&amp;',
    "'"    => '&#39;',
    '('    => '&#40;',
    ')'    => '&#41;',
    '<'    => '&lt;',
    '>'    => '&gt;',
};
use constant HTM2STR => {reverse %{__PACKAGE__->STR2HTM}};
our($PSGI_ENV, $PSGI_REQ);

__PACKAGE__->_mk_accessors_(qw/error request view/);
*req = \&request;

sub args { shift->route->{args} }

sub default_config { shift->project->config->App->Web }

sub default_view {
    my $c = shift;
    $c->controller->PATH.$c->action.'.'.$c->DEFAULT_VIEW_EXT;
}

sub download_header {
    my($c, $fn) = @_;
    die "No file name" if !$fn;
    $c->res->content_type('application/download');
    $c->res->header('Content-Disposition' => qq(attachment; filename="$fn"));
    $c;
}

sub dispatch {
    my($c, $path, $opt) = (shift, shift, shift || {});
    
    $c->{error} = undef;
    my $st = eval{
        my $r = $c->routing($path) || return $c->http_error(404);
        $c->res->status(200);
        $c->route($r);
        $c->_dispatch($r, $opt);
    };
    if($@){
        $c->{error} = $@;
        $c->res->status(500);
        return !1;
    }elsif($::ENV{FLAPP_DEBUG} && $c->{error}){
        $c->debug(\($c->{error}));
    }
    $st;
}

sub finalize {
    my $c = shift;
    my $res = $c->res;
    
    $c->debug('finalize') if $::ENV{FLAPP_DEBUG};
    if($res->status !~ /^3/){
        $res->content_type($c->ua->content_type) if !$res->content_type;
        $c->finalize_body if !defined $res->{body};
    }
    $c->finalize_session if $c->session_enabled;
    if($res->{body} && (my $f = $c->ua->filter_output)){
        if(!ref $res->{body}){
            $f->($res->{body});
        }elsif($res->{body}->can('filter_output')){
            $res->{body}->filter_output($f);
        }
    }
    $res->finalize;
}

sub finalize_body {
    my $c = shift;
    my $res = $c->res;
    my $st = $res->status;
    if($st == 200 && !eval{ $c->render }){
        $c->log('__DIE__', $@ || $c->error);
        $res->status($st = 500);
        $res->{body} = undef;
    }
    $c->view("/$st.".$c->DEFAULT_VIEW_EXT)->render if $st != 200;
    if(!defined $res->{body}){
        require HTTP::Status;
        $res->content_type('text/plain');
        $res->body("$st ".HTTP::Status::status_message($st));
    }
}

sub finalize_session {
    my $c = shift;
    my $s = $c->session;
    if(my $f = $s->get('.flash')){
        if($f->[1]){
            shift @$f;
            $s->set('.flash', $f);
        }else{
            $s->remove('.flash')
        }
    }
    $s->finalize($c->res);
}

sub flash { shift->_flash(1, @_) }

sub flash_now { shift->_flash(0, @_) }

sub _flash {
    my($c, $i, $k) = (shift, shift, shift);
    die 'No key for flash' if !$k;
    my $s = $c->session;
    my $f = $s->get('.flash') || [{}];
    if(@_){
        $f->[$i]{$k} = $_[0];
        $s->set('.flash', $f);
        return $c;
    }
    $f->[0]{$k};
}

sub flash_keep {
    my $c = shift;
    my $s = $c->session;
    my $f = $s->get('.flash') || return $c;
    $f->[1] = $f->[0];
    $s->set('.flash', $f);
    $c;
}

sub html {
    my $c = shift;
    my $r = ref $_[0] ? shift : do{ \(my $s = shift) };
    $$r =~ s/(\r\n?|[\n"&'()<>])/$c->STR2HTM->{$1}/eg;
    $$r;
}

sub http_error {
    my($c, $st) = @_;
    my($file, $line) = (caller)[1, 2];
    $c->res->status($st);
    $c->error("$st at $file line $line.");
    !1;
}

sub include_path {
    my $c = shift;
    $c->{include_path} ||= [map{ "$_/view" } $c->app_root, $c->project_root, Flapp->root_dir];
}

sub locate_view {
    my $c = shift;
    my $v = shift || die 'No view';
    $c->{route} ? ($v = $c->controller->PATH.$v) : die qq{View "$v" is not absolute}
        if substr($v, 0, 1) ne '/';
    my $sfx = shift || '';
    my $lvc = $c->_global_->{locate_view_cache} ||= {};
    my $loc = $lvc->{$v.$sfx} || do{
        my $loc;
        foreach(@{$c->include_path}){
            last if $sfx && -f "$_$v$sfx" && ($loc = [$_]);
            last if -f $_.$v && ($loc = [$_, $sfx ? $v : undef]);
        }
        return undef if !$loc;
        $loc->[0] = $c->_symbol_($loc->[0]);
        $lvc->{$v.$sfx} = $loc;
    };
    [${$loc->[0]}, $loc->[1] || $v.$sfx];
}

sub log {
    my($class, $sig, $msg) = @_;
    local $::SIG{__WARN__};
    local $::SIG{__DIE__};
    $class->debug(\$msg, "\x1B[31m") if $::ENV{FLAPP_DEBUG};
    
    my $req = Plack::Request->new($PSGI_ENV);
    my $body = '';
    if($req->content_length){
        eval{ $PSGI_REQ->body_parameters } if $PSGI_REQ; #read body if not yet,
        $body = $PSGI_ENV->{'plack.request.body_parameters'};
        $body &&= $class->Request->MultiValueHash->new(@$body)->as_hashref;
        $body = $body && eval{ local $Flapp::UTF8; $class->dump($body) } || '?';
        Encode::_utf8_on($body) if $Flapp::UTF8 && require Encode;
    }
    
    my $lgr = $class->project->logger;
    local $Flapp::Logger::DEBUG;
    $lgr->print($lgr->Util->ary2tsv(
        $lgr->now->hms,
        $sig,
        $class->app_name,
        $msg,
        $req->address,
        $req->method.' '.$req->uri,
        $req->headers->as_string,
    )."\t$body\n");
}

sub new {
    my $c = shift->_new_({});
    $c->req($c->Request->new(shift, $c));
    $c;
}

sub open_view {
    my $c = shift;
    my $v = $c->view || $c->default_view;
    my $loc = $c->locate_view($v, $c->ua->view_suffix) || return !$c->error(qq{Can't locate "$v"});
    my $vc = $c->view_class($loc);
    $c->debug(\qq{$vc->open("$loc->[0]$loc->[1]")}) if $::ENV{FLAPP_DEBUG};
    $vc->open($c, $loc);
}

sub path {
    my $c = shift;
    my $pfx = $c->uri_prefix || return $c->req->path;
    my $path;
    ($path = $c->req->path) =~ s%^\Q$pfx\E/%/% ? $path : '';
}

sub prepare {
    my $class = shift;
    my $proj = $class->project;
    
    $proj->begin;
    $proj->logger->print('');
    $Flapp::Logger::DEBUG = 1 if $::ENV{FLAPP_DEBUG};
    $proj->end;
}

sub project_options {
    my $class = shift;
    return {
        dbh_auto_reconnect => 1,
        trace => {
            exclude => qr/^(?:Plack|HTTP::Server::PSGI|\(eval\)|Try::Tiny)/,
            warn    => sub{ $class->log('__WARN__', @_); },
        },
    };
}

sub psgi {
    (my $class = shift)->prepare;
    
    sub{
        my($c, $term);
        if(!$::SIG{TERM}){
            $term = 0;
            $::SIG{TERM} = sub{ $term = 1; delete $::SIG{TERM} };
        }
        my $res = eval{
            $class->project->begin($class->project_options);
            local *STDOUT = gensym if !$::ENV{FLAPP_DEBUG};
            $c = $class->new($PSGI_ENV = shift);
            $c->_weaken_($PSGI_REQ = $c->req);
            
            $c->psgi_begin && $c->dispatch($c->path, {begin => 1, auto => 1, end => 1});
            $class->log('__DIE__', $c->error) if $c->res->status == 500;
            $c->finalize;
        } || do{
            $class->log('__DIE__', $@);
            [500, [], ['500 Internal Server Error']];
        };
        sub{
            eval{ shift->($res) };
            $class->log('__DIE__', $@) && eval{ $res->[2]->close } if $@;
            $c->psgi_end;
            $c->req->finalize;
            $res = $c = undef;
            $class->project->end;
            undef $PSGI_ENV;
            delete $::SIG{TERM} if defined $term;
            kill 'TERM', $$ if $term;
        };
    };
}

sub psgi_begin {
    my $c = shift;
    $c->debug('=', "\x1B[34m")
        ->debug($c->app_name.'->psgi_begin')
        ->debug(\('parameters: '.$c->_dump_($c->req->parameters))) if $::ENV{FLAPP_DEBUG};
    1;
}

sub psgi_end { $_[0]->debug($_[0]->app_name.'->psgi_end') if $::ENV{FLAPP_DEBUG} }

sub redirect_for {
    my $c = shift;
    my $cd = @_ == 3 && pop;
    $c->res->redirect($c->uri_for(@_), $cd);
}

sub render {
    my $c = shift;
    my $vh = $c->open_view || return;
    $vh->render(shift || \($c->res->{body} = ''));
    $vh->close;
    $c;
}

sub response {
    my $c = shift;
    $c->{response} ||= $c->Response->new;
}
*res = \&response;

sub routing {
    my($c, $path) = @_;
    my $debug = $::ENV{FLAPP_DEBUG};
    
    $c->debug(qq{routing: "$path"}) if $debug;
    foreach(@{$c->_global_->{routing_cache} ||= $c->routing_cache}){
        my %m;
        (@m{@{$_->[1]}} = ($path =~ $_->[0])) || next;
        $c->debug(\('matched as '.$c->dump($_->[2]))) if $debug;
        
        my $r = $c->routing_matched({%{$_->[2][1]}, args => \%m}, $path);
        next if !$r && (!$debug || $c->debug(\'$c->routing_matched failed.'));
        
        my $ctl = $c->controller($r->{controller});
        next if !$ctl && (!$debug || $c->debug(\qq{no controller for "$r->{controller}"}));
        
        my $code = $ctl->can($r->{action});
        my $arg = $code && $ctl->ACTION_ARGS->{$code};
        next if !$arg && (!$debug || $c->debug(\qq{No ":Action" for $ctl->$r->{action}}));
        
        if(my($ng) = grep{ !$arg->{$_} } keys %{$r->{args}}){
            next if !$debug || $c->debug(\qq{args ":$ng" not allowed at "$ctl->$r->{action}"});
        }
        
        $c->debug(\('found '.$c->dump($r))) if $debug;
        return $r;
    }
    $c->debug(\'no route found.') if $debug;
    undef;
}

sub routing_cache {
    my $c = shift;
    my @rc;
    foreach(@{$c->ROUTING}){
        my($path, $r) = @$_;
        my(@arg, %arg);
        (my $ptn = $path) =~ s%:([0-9a-z_]+)%
            my $arg = $c->ROUTING_ARGS->{$1} || die qq{ROUTING_ARGS ":$1" is not defined};
            push @arg, $1;
            $arg{$1} = 1;
            qr/($arg)/;
        %eg;
        foreach(qw/controller action/){
            my $msg = ($r->{$_} && $arg{$_}) ? 'duplicate' :
                (!$r->{$_} && !$arg{$_}) ? 'missing' : next;
            die "Invalid ROUTING: $msg $_ for ".$c->dump([$path => $r]);
        }
        push @rc, [qr/^$ptn\z/, \@arg, $_];
    }
    \@rc;
}

sub routing_matched {
    my($c, $r) = @_;
    my $args = $r->{args};
    
    if(exists $args->{action}){
        return undef if $args->{action} eq 'index';
        $r->{action} = delete $args->{action};
    }
    if(exists $args->{controller}){
        return undef if $args->{controller} eq 'root';
        $r->{controller} = $c->Util->path2class(delete $args->{controller}) || return undef;
    }
    $r;
}

sub session {
    my $c = shift;
    die 'Session is not enabled' if !$c->session_enabled;
    $c->{session} ||= $c->Session->new($c);
}

sub session_dir { shift->app_root_tmp('sessions') }

sub session_enabled {
    my $c = shift;
    if(@_){
        $c->{session_enabled} = shift;
        return $c;
    }
    defined $c->{session_enabled} ? $c->{session_enabled} : 1;
}

sub stash {
    my $c = shift;
    my $s = $c->{stash} ||= {};
    return $s if !@_;
    return $s->{+shift} if @_ == 1;
    while(@_){
        my $k = shift;
        $s->{$k} = shift;
    }
    $c;
}

sub static_roots {
    my $c = shift;
    [map{ "$_/public/static" } $c->app_root, $c->project_root];
}

sub upload_dir { shift->app_root_tmp('uploads') }

sub uri_for {
    my($c, $uri, $q) = @_;
    $uri = $c->uri_prefix.$uri if $uri eq '/' || $uri =~ m%^/[^/]%;
    if($q){
        my $ref = ref $q;
        die qq{Invalid ref "$ref"} if $ref ne 'HASH' && $ref ne $c->req->MultiValueHash;
        $uri .= (index($uri, '?') >= 0 ? '&' : '?').$q
            if %$q && ($q = $c->Util->uri_escape($q, 1)) ne '';
    }
    $uri;
}

sub uri_prefix { '' }

sub user_agent {
    my $c = shift;
    $c->{user_agent} ||= $c->UserAgent->new($c);
}
*ua = \&user_agent;

sub view_class { shift->View->FT }

1;
