use Flapp qw/-m -s -w/;
use Encode;

my $exec = sub{ eval "package main; no strict 'vars'; $_[0]" };
my $lclr = "\n\x1B[1A\x1B[2K";
my $left = sub{ $_[0] ? "\x1B[$_[0]D" : '' };
my $reg = qr/^(\x1B(\[[0-9]*)?|[\xC2-\xDF]|[\xE0-\xEF][\x80-\xBF]?|[\xF0-\xF7][\x80-\xBF]{,2})\z/;
my $right = sub{ $_[0] ? "\x1B[$_[0]C" : '' };
my $sizeof = sub{
    Encode::_utf8_off(my $s = shift);
    Encode::from_to($s, 'utf8', 'cp932');
    length $s;
};

sub{
    my $os = shift;
    my $hf = $os->project_root.'/tmp/.console_history';
    $hf = undef if !-f $hf;
    my($buf, $line, $pos, $src, $hpos, @hist, $H) = ('', '', 0, '', 0);
    my $add_h = sub{
        return if @hist && $hist[-1] eq $_[0];
        push @hist, $_[0];
        print $H $_[0]."\n" if $H;
        return if ($hpos = @hist) <= 100;
        shift(@hist);
        $hpos--;
    };
    my $load_h = sub{
        $os->open(my $H, $_[0]) || die "$!($_[0])";
        while(my $line = <$H>){
            chomp $line;
            $add_h->($line);
        }
        close($H);
    };
    
    if(my $pid = fork){
        local $::SIG{INT} = 'IGNORE';
        chomp(my $g = `stty -g`);
        `stty -icanon -echoctl`;
        wait;
        print $lclr;
        `stty $g`;
        if($hf){
            $load_h->($hf);
            $load_h->("$hf.$pid");
            $os->open(my $H, '>', $hf) || die "$!($hf)";
            print $H $_."\n" for @hist;
            close $H;
            $os->unlink("$hf.$pid");
        }
        return;
    }
    
    if($hf){
        $load_h->($hf);
        $os->open($H, '>', "$hf.$$") || die "$!($hf.$$)";
        $H->autoflush;
    }
    
    print "$lclr>> ";
    local $::SIG{INT};
    while(1){
        $buf .= getc STDIN;
        next if $buf =~ $reg;
        Encode::_utf8_on(my $chr = $buf);
        $buf = '';
        
        #$os->cat($os->Util->uri_escape($chr)."\n", '>>', '/dev/pts/2');
        if($chr eq "\x08" || $chr eq "\x7F"){ #BS
            substr($line, --$pos, 1) = '' if $pos > 0;
        }elsif($chr eq "\x1B[3\x7E"){ #DEL
            substr($line, $pos, 1) = '' if $pos < length($line);
        }elsif($chr eq "\x0A"){ #RETURN
            $add_h->($line) if $line ne '';
            ($line, $pos, $src, $hpos) = ('', 0, $src.$line."\n", int @hist);
        }elsif($chr eq "\x04"){ #Ctrl+D
            (print "\n") && $add_h->($line) if $line ne '';
            $src .= $line;
            Encode::_utf8_off($src) if !$Flapp::UTF8;
            my @r = $exec->($src);
            print $lclr.($@ ? "\x1B[31m$@\x1B[0m" : '=> '.$os->dump(@r > 1 ? \@r : $r[0])."\n");
            ($line, $pos, $src, $hpos) = ('', 0, '', int @hist);
        }elsif($chr eq "\x1B[A"){ #up
            print "\x1B[1B";
            $pos = length($line = $hist[--$hpos]) if $hpos;
        }elsif($chr eq "\x1B[B"){ #down
            print "\x1B[1A";
            $hpos++ if $hpos <= $#hist;
            $pos = length($line = $hpos <= $#hist ? $hist[$hpos] : '');
        }elsif($chr eq "\x1B[C"){ #right
            next if $pos >= length($line) && print $left->(1);
            $pos++;
        }elsif($chr eq "\x1B[D"){ #left
            next if !$pos && print $right->(1);
            $pos--;
        }else{
            substr($line, $pos++, 0) = $chr;
        }
        
        my $buf = $line;
        Encode::_utf8_off($buf) if !$Flapp::UTF8;
        print "$lclr>> $buf".$left->($sizeof->(substr($line, $pos)));
    }
    exit;
};
