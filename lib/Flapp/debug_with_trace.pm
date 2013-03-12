use Flapp qw/-m -s -w/;

sub{
    my($proj, $msg, $filter) = @_;
    my $ln = $proj->Util->debug_line;
    $proj->tracer('__WARN__', {
        %{$proj->trace_option || {}},
        warn => sub{
            my $st = '';
            if($::ENV{FLAPP_DEBUG} > 1){
                ($st = shift) =~ s/^ at __WARN__.+\n//;
                1 while $filter && $st =~ s/$filter//m;
            }
            print STDERR "$ln$msg\n$st$ln";
        },
    })->('');
};
