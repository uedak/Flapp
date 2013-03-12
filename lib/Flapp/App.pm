package Flapp::App;
use Flapp qw/-b Flapp::Object -m -r -s -w/;

sub action { shift->route->{action} }

sub app_config {
    my $app = shift;
    $app->project->config->apps->{$app->app_name} || $app->default_config;
}

sub app_name { substr($_[0]->_class_, length($_[0]->project) + 2) }

sub app_root { $_[0]->project_root.'/apps/'.$_[0]->app_name }

sub app_root_tmp {
    my $c = shift;
    return $c->app_root."/tmp/$_[0]" if !$c->project->is_test;
    my $dir = $c->project_root.'/tmp/apps/'.$c->app_name.'/tmp';
    $c->OS->mkdir_p($dir) || die "$!($dir)" if !-d $dir;
    
    $dir .= "/$_[0]";
    $c->OS->mkdir($dir) if !-d $dir && -d $c->app_root."/tmp/$_[0]";
    $dir;
}

sub controller {
    my $c = shift;
    return $c->controller($c->route->{controller}) if !@_;
    my $ctl = $c->Controller.'::'.shift;
    (my $pm = "$ctl.pm") =~ s%::%/%g;
    ($::INC{$pm} || (-f $c->app_root."/lib/$pm") && (require $pm)) ? $ctl : undef;
}

sub debug {
    my $c = shift;
    return !!$::ENV{FLAPP_DEBUG} if !@_;
    return $c if !$::ENV{FLAPP_DEBUG};
    print STDERR $_[1] if $_[1]; #color
    if(!ref $_[0]){
        print STDERR $_[0] eq '=' ? $c->Util->debug_line('=') : "[DEBUG] $_[0]\n";
    }else{
        (my $msg = ${$_[0]}) =~ s/[\t\n\r ]+\z//;
        $msg =~ s/\n/\n - /g;
        print STDERR " - $msg\n";
    }
    print STDERR "\x1B[0m" if $_[1];
    $c;
}

sub _dispatch {
    my($c, $r, $opt) = @_;
    my $debug = $::ENV{FLAPP_DEBUG};
    
    my $dc = $c->_global_->{dispatch_cache}{$r->{controller}}
     ||= $c->dispatch_cache($r->{controller});
    
    $c->debug('dispatch') if $debug;
    if($dc->{begin} && $opt->{begin}){
        $c->debug(\"$dc->{begin}->begin") if $debug;
        $dc->{begin}->begin($c) || return !1;
    }
    if($dc->{auto} && $opt->{auto}){
        foreach(@{$dc->{auto}}){
            $c->debug(\"$_->auto") if $debug;
            $_->auto($c) || return !1;
        }
    }
    $c->__dispatch($r, $opt);
    if($dc->{end} && $opt->{end}){
        $c->debug(\"$dc->{end}->end") if $debug;
        $dc->{end}->end($c);
    }
    1;
}

sub __dispatch {
    my($c, $r, $opt) = @_;
    my($ctl, $act) = ($c->controller($r->{controller}), $r->{action});
    $c->debug(\"$ctl->$act") if $::ENV{FLAPP_DEBUG};
    @_ = ($ctl, $c);
    goto $ctl->can($act);
}

sub dispatch_cache {
    my($c, $ctl) = @_;
    my @ctl = split /::/, $ctl;
    $ctl[$_] = $ctl[$_ - 1].'::'.$ctl[$_] for 1 .. $#ctl;
    unshift @ctl, 'Root' if $ctl ne 'Root';
    
    my %dc;
    foreach($c->Controller, map{ $c->controller($_) } @ctl){
        next if !$_;
        $dc{begin} = $_ if $_->_code_('begin');
        push @{$dc{auto} ||= []}, $_ if $_->_code_('auto');
        $dc{end} = $_ if $_->_code_('end');
    }
    \%dc;
}

sub route {
    my $c = shift;
    return $c->{route} || die 'No route' if !@_;
    $c->{route} = shift;
    $c;
}

sub sweep {}

1;
