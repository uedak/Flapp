use Flapp qw/-m -s -w/;

sub{
    my $c = shift;
    my $proj = $c->project;
    my $os = $proj->OS;
    
    my $apps = $proj->project_root.'/apps';
    foreach my $app (@{$os->ls($apps)}){
        next if !-d "$apps/$app/lib";
        $proj->app($app)->sweep($c);
    }
    
    my $dir = $proj->project_root.'/log';
    my $tdy = $proj->today;
    my $rn;
    $rn = sub{
        my($f, $i) = (shift, shift || 0);
        my $t = $f.'.'.($i + 1);
        $rn->($f, $i + 1) if -f "$dir/$t";
        $f .= ".$i" if $i;
        $os->rename("$dir/$f" => "$dir/$t") || die "$!($dir/$f => $dir/$t)";
        $c->log("rename $f => $t");
    };
    my @ym;
    
    foreach my $f (@{$os->ls($dir)}){
        (my($ym) = $f =~ /^([0-9]{4}-[0-9]{2})/) || next;
        next if $f eq $ym && -d "$dir/$ym" && push @ym, $ym;
        next if substr($f, -4) ne '.log' || substr($f, 0, 10) eq $tdy;
        
        if($f =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})_default_(.+)\.log\z/){
            my($ymd, $host) = ($1, $2);
            my $w = my $d = my $u = 0;
            $os->open(my $H, "$dir/$f") || die "$!($dir/$f)";
            while(my $line = <$H>){
                my $sig = substr($line, 9, 6);
                $sig eq '__WARN' ? $w++ :
                $sig eq '__DIE_' ? $d++ :
                $u++;
            }
            close($H);
            if(!$w && !$d && !$u){
                $c->log("$ymd $host OK.");
            }else{
                $c->_log('?', "$ymd $host has some errors(warn: $w, die: $d, unknown: $u)");
            }
        }
        
        $os->mkdir("$dir/$ym");
        $rn->("$ym/$f") if -f "$dir/$ym/$f";
        $os->rename("$dir/$f" => "$dir/$ym/$f") || die "$!($dir/$f => $dir/$ym/$f)";
        $c->log("rename $f => $ym");
    }
    
    my $arc = $tdy->clone->add_month($tdy->day <= 7 ? -2 : -1)->strftime('%Y-%m');
    foreach my $ym (sort grep{ $_ le $arc } @ym){
        $os->system('tar -C %path -zcf %path.tar.gz %path', $dir, "$dir/$ym", $ym) && die "$!($ym)";
        $c->log("tar: $ym => $ym.tar.gz");
        $os->rm_rf("$dir/$ym") || die "$!($ym)";
        $c->log("rm: $ym");
    }
};
