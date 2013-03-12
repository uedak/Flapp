use Flapp qw/-m -s -w/;

sub{
    my($self, $cr, $ji, $me) = @_;
    my($qt, $pr) = ($self->REG_QT, $self->REG_PR);
    my @j = sort{ $b->{depth} <=> $a->{depth} || $b->{-as} cmp $a->{-as} } values %$ji;
    
    my $pos = 0;
    while($$cr =~ /\G\s*((?:(\*|\w+)\.)?(\*|\w+)|(?:[^"'(),]+|$qt|$pr)+)\s*(?:,|\z)/g){
        $pos = pos $$cr;
        next if !defined $3 && push @{$ji->{$me}{select}{cols}}, $1;
        foreach my $as (!defined $2 ? $me : $2 eq '*' ? map{ $_->{-as} } @j : $2){
            my $sel = ($ji->{$as} || die qq{No join alias "$as" for "$1"})->{select} ||= {};
            $sel->{has}{lc $3} = $3 eq '*' || push @{$sel->{cols}}, "$as.$3";
        }
    }
    die 'Parse error near "'.substr($$cr, $pos).'"' if $pos < length $$cr;
    
    my(@cols, $prev);
    foreach my $j (@j){
        my $sel = $j->{select} || next;
        my $jsch = $j->{schema};
        $sel->{pk}{$_} = 1 for @{$jsch->primary_key || die $jsch->_dmsg_(7)};
        if($sel->{has}{'*'}){
            push @{$sel->{cols}}, $self->asterisk_for($jsch->table, $j->{-as});
            push @{$sel->{cols}}, "'|'" if $prev;
        }else{
            foreach my $ci (@{$jsch->column_infos}){
                next if !$ci->{pk} && !$ci->{fk};
                $sel->{has}{$ci->{name}} ||= push @{$sel->{cols}}, "$j->{-as}.$ci->{name}";
            }
        }
        unshift @cols, @{$sel->{cols}};
        
        $j->{parent}{select} ||= {};
        delete $j->{children} if !@{$j->{children} = [grep{ $_->{select} } @{$j->{children}}]};
        $self->_weaken_($j->{next} = $prev) if $prev;
        $prev = $j;
    }
    $$cr = join(', ', @cols);
};
