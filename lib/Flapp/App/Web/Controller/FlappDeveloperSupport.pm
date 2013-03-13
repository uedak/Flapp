package Flapp::App::Web::Controller::FlappDeveloperSupport;
use Flapp qw/-b Flapp::App::Web::Controller -m -s -w/;

sub index :Action {
    my($self, $c) = @_;
}

sub gvmon :Action {
    my($self, $c) = @_;
    my @k = $c->req->param('k');
    my $g = \%Flapp::G;
    $g = $g->{$_} for @k;
    $c->stash(keys => \@k, g => $g);
    $c->res->body($c->open_view);
}

sub webgrep :Action {
    my($self, $c) = @_;
    my $p = $c->req->params;
    %$p = %{$c->inflate_params($p)};
    
    my(@dirs, @d, @excludes);
    foreach my $s (@{$self->_webgrep_search_roots($c)}){
        push @dirs, [$s->[0], $c->OS->ls($s->[0]) || die "$!($s->[0])"];
        push @d, map{ "$s->[0]/$_" } @{$s->[1]};
    }
    $c->stash(dirs => \@dirs);
    $c->stash(excludes => my $x = $self->_webgrep_exclude_exts($c));
    
    if($p->{'.search'}){
        return $c->flash_now(error => '検索条件を入力して下さい') if $p->{-p} eq '' || !@{$p->{-d}};
        $c->stash(fetch => my $f = {});
        $f->{p} = $p->{-r} ? $p->{-p} : quotemeta($p->{-p});
        $f->{p} = $p->{-i} ? qr/($f->{p})/i : qr/($f->{p})/;
        $f->{x} = {map{ $_ => 1 } @{$p->{-x}}};
        $f->{n} = $p->{-n} || 0;
        $c->OS->open($f->{H},
            "find %path -type d -name '.*' -prune -o -type f -print |", $p->{-d}) || die $!;
        $c->res->body($c->open_view);
    }else{
        $p->{-d} = \@d;
        $p->{-x} = [map{ $_->[0] } grep{ $_->[1] } map{ @$_ } @$x];
    }
}

sub _webgrep_exclude_exts {
    my($self, $c) = @_;
    [
        [
            [pm   => 0],
            [pl   => 0],
            [psgi => 0],
            [fcgi => 0],
            [cgi  => 0],
            [ft   => 0],
            [t    => 1],
        ],
        [
            [js   => 1],
            [css  => 1],
            [scss => 1],
            [gif  => 1],
            [jpg  => 1],
            [png  => 1],
            [swf  => 1],
            [ico  => 1],
            [gz   => 1],
            [log  => 1],
            [ses  => 1],
            [tsv  => 1],
            [txt  => 1],
        ],
    ];
}

sub _webgrep_fetch {
    my($self, $c) = @_;
    my $f = $c->stash('fetch') || return;
    while(my $path = $f->{H}->getline){
        next if $path =~ /\.([a-z]+)$/ && $f->{x}{$1};
print $path;
        chomp($path);
        my($line, $i, $m, $n, @buf, @lines);
        $c->OS->open(my $H, $path) || die "$!($path)";
        no warnings 'utf8';
        while(($line = [++$i]) && ($line->[1] = <$H>)){
            chomp $line->[1];
            ($m, $n) = (1, 0) if $self->_webgrep_macth($c, $f, $line);
            if(!$m){
                shift @buf if ++$n > $f->{n};
                push @buf, $line if $f->{n};
                next;
            }
            push @buf, $line;
            next if ++$n <= $f->{n};
            push @lines, splice(@buf), [];
            $m = $n = 0;
        }
        push @lines, splice(@buf), [] if $m && @buf;
        $m = $self->_webgrep_macth($c, $f, $line = [0, $path]);
        next if !@lines && !$m;
        @lines ? pop @lines : (@lines = []);
        defined $_->[1] && !defined $_->[2] && ($_->[2] = $c->html($_->[1])) for ($line, @lines);
        return {path => $line->[2], lines => \@lines}
    }
    $f->{H}->close;
    return;
}

sub _webgrep_macth {
    my($self, $c, $f, $line) = @_;
    my($htm, $ofs) = ('', 0);
    while($line->[1] =~ /$f->{p}/g){
        my $pos = pos $line->[1];
        $htm .= $c->html(substr($line->[1], $ofs, $pos - $ofs - length($1)));
        $ofs = $pos;
        $htm .= '<b>'.$c->html($1).'</b>';
    }
    return if $htm eq '';
    $line->[2] = $htm.$c->html(substr($line->[1], $ofs));
    1;
}

sub _webgrep_search_roots {
    my($self, $c) = @_;
    [
        [Flapp->root_dir  => [qw/lib/]],
        [$c->project_root => [qw/apps lib mail view/]],
    ];
}

1;
