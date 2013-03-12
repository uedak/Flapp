use Flapp qw/-m -s -w/;;

my $as_ar = sub{
    my $r = shift;
    !defined $r ? [] : ref $r eq 'ARRAY' ? $r : ref $r eq 'HASH' ? do{
        my @a;
        /[^0-9]/ ? return $r : ($a[$_] = $r->{$_}) for keys %$r;
        \@a;
    } : [$r];
};

my $as_hr = sub{
    my $r = shift;
    !defined $r ? {} : ref $r eq 'HASH' ? $r : ref $r eq 'ARRAY' ? do{
        my %h;
        defined $r->[$_] && ($h{$_} = $r->[$_]) for 0 .. $#$r;
        \%h;
    } : die '?';
};

my $set = sub{
    my($ip, $p, $k) = @_;
    
    if(ref $ip->{$k} eq 'ARRAY'){
        push @{$ip->{$k}}, ref $p->{$k} eq 'ARRAY' ? @{$p->{$k}} : $p->{$k};
    }elsif(defined $ip->{$k}){
        die $k;
    }else{
        $ip->{$k} = $p->{$k};
    }
    1;
};

sub{
    my($c, $p) = @_;
    my %ip;
    
    foreach(keys %$p){
        my $i = index($_, '[');
        next if $i <= 0 && $set->(\%ip, $p => $_);
        pos $_ = $i;
        my @k;
        push @k, $1 while /\G\[([^\[\]]*)\]/gc;
        next if pos $_ < length $_ && $set->(\%ip, $p => $_) && !(pos $_ = 0);
        
        my($ip, $k) = (\%ip, substr($_, 0, $i));
        while(@k){
            if(ref $ip eq 'HASH'){
                if(!$k[0]){ # 0 or ''
                    $ip = $ip->{$k} = $as_ar->($ip->{$k});
                }elsif($k[0] =~ /[^0-9]/){
                    $ip = $ip->{$k} = $as_hr->($ip->{$k});
                }else{
                    $ip = $ip->{$k} ||= {};
                }
            }else{
                if(!$k[0]){ # 0 or ''
                    $ip = $ip->[$k] = $as_ar->($ip->[$k]);
                }elsif($k[0] =~ /[^0-9]/){
                    $ip = $ip->[$k] = $as_hr->($ip->[$k]);
                }else{
                    $ip = $ip->[$k] ||= {};
                }
            }
            $k = shift @k;
        }
        
        if(ref $ip eq 'ARRAY'){
            ref $p->{$_} ? push @$ip, @{$p->{$_}} :
            $p->{$_} ne '' && ($ip->[$k || 0] = $p->{$_});
        }else{
            !defined $ip->{$k} ? $ip->{$k} = $p->{$_} : die $k;
        }
    }
    
    \%ip;
};
