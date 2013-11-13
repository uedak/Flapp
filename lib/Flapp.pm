package Flapp;
use Flapp::Core qw/-b Flapp::Object -m -r -s -w/;
our $VERSION = '0.9011';
our($BEGIN, %G, $MAIL_SPOOL_DIR, $NOW, %OBJECT, $UTF8);

sub import {
    my $pkg = scalar caller;
    (require utf8) && &utf8::import if $UTF8;
    shift->Core->_import($pkg, @_)
}

sub app {
    my($proj, $app) = @_;
    $proj->_global_->{app}{$app} ||= do{
        my $lib = $proj->project_root."/apps/$app/lib";
        unshift @::INC, $lib if (!grep{ $_ eq $lib } @::INC) && -d $lib;
        require "$proj/$app.pm" && $proj.'::'.$app;
    };
}

sub begin {
    my $proj = shift;
    if($BEGIN){
        warn "$proj->begin called again";
        $proj->end;
    }
    undef %OBJECT;
    my $opt = $BEGIN->{OPT} =
        {dbh_auto_reconnect => 0, schema_cache => {}, trace => {}, %{shift || {}}};
    foreach(qw/__WARN__ __DIE__/){
        $BEGIN->{SIG}{$_} = $::SIG{$_} || '';
        $::SIG{$_} = $proj->tracer($_, $opt->{trace});
    }
    $proj;
}

sub config {
    my $proj = shift;
    $proj->_global_->{config}{$proj->env} ||= $proj->Config->load($proj->env);
}

sub dbh {
    my($proj, $db) = (shift, shift || 'Default');
    return $BEGIN->{DBH}{"$proj.$db"} ||= do{
        my $dbh = $proj->DBI->dbh($proj, $db);
        $dbh->auto_reconnect(1) if $BEGIN->{OPT}{dbh_auto_reconnect};
        $dbh;
    } if $BEGIN && !@_;
    $proj->DBI->dbh($proj, $db, shift || 0);
}

sub end {
    my $proj = shift;
    if($BEGIN){
        $_->finalize for values %{$proj->_global_->{dbh_pool}};
        undef %{$BEGIN->{OPT}{schema_cache}};
        $proj->found_mem_leak if %OBJECT;
        undef %OBJECT;
        $::SIG{$_} = $BEGIN->{SIG}{$_} for qw/__WARN__ __DIE__/;
        $BEGIN = undef;
    }else{
        require Carp;
        Carp::carp "$proj->begin not called";
    }
}

sub env { $::ENV{HARNESS_ACTIVE} ? 'test' : ($::ENV{FLAPP_ENV} || 'development') }

sub found_mem_leak {
    my @o = sort keys %OBJECT;
    @o = (@o[0 .. 2], '...') if @o > 3;
    warn 'Found mem leak('.join(', ', @o).')';
}

sub hostname { $Flapp::G{hostname} ||= do{ require Sys::Hostname; &Sys::Hostname::hostname() } }

sub is_test { shift->env eq 'test' }

sub logger {
    my $proj = shift;
    my $nm = shift || 'default';
    $proj->_global_->{logger}{$nm} ||= $proj->Logger->new($nm);
}

sub now { shift->Time->now(@_) }

sub root_dir {
    my $pm = "$_[0].pm";
    $::INC{$pm} =~ m%^(.+)/lib/\Q$pm\E\z% ? $1 : die qq{Can't detect root for "$::INC{$pm}"};
}

sub schema {
    my $db = $_[1] || return shift->Schema->Default;
    shift->Schema->$db;
}

sub schema_cache { $BEGIN && $BEGIN->{OPT}{schema_cache}  }

sub today { shift->Date->today(@_) }

sub tracer {
    my($proj, $sig, $opt) = @_;
    my $die = $sig eq '__DIE__';
    
    sub{
        local $::SIG{$sig} = $BEGIN->{SIG}{$sig} if $BEGIN;
        my($i, @t);
        while(my($pkg, $path, $line, $sub) = caller($i++)){
            push @t, [$path, $line, $i == 1 ? $sig : $sub];
            last if $die && $sub eq '(eval)';
        }
        
        my $msg = $_[0];
        $proj->Util->utf8_on($msg) if $UTF8;
        $msg =~ s/ at \Q$t[0]->[0]\E line \Q$t[0]->[1]\E\.\n\z/\n/;
        while(my $t = shift @t){
            next if(@t && $opt->{exclude} && $t->[2] =~ $opt->{exclude});
            $t->[0] =~ s%^\Q$_/\E%% && last for @::INC;
            $msg .= " at $t->[2]($t->[0] $t->[1])\n";
        }
        $i->INTERPOLATE_TRACE($sig, \$msg) if ($i = $opt->{interpolator});
        if($die){
            $opt->{die} ? $opt->{die}->($msg) : die $msg;
        }else{
            $opt->{warn} ? $opt->{warn}->($msg) : warn $msg;
        }
    };
}

sub trace_option { $BEGIN && $BEGIN->{OPT}{trace} }

sub validate {
    my $proj = shift;
    my $vr = ref $_[0] ? shift : do{ \(my $v = shift) };
    my($vc, @e);
    foreach($proj->validate_options(@_)){
        my $method = $_->[0];
        push @e, ($vc ||= $proj->Validator)->$method($vr, $_->[1]);
    }
    @e;
}

sub validate_options {
    shift;
    map{ ref $_ ? $_ : /^([0-9a-z_]+)\((.*)\)\z/ ? [$1, $2] : [$_] } @_;
}

1;
__END__

=head1 NAME

Flapp - Fast/Lightweight Application Platform

=head1 COPYRIGHT

Copyright 2011- Kazutaka Ueda

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
