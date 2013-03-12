package MyProject;

BEGIN{
    my $r = $::ENV{FLAPP_ROOT} =~ /(.+)/ && $1 || '__FLAPP_ROOT__';
    if($::INC{'Flapp.pm'}){
        my $f = Flapp->root_dir;
        die qq{Can't use diffirent FLAPP_ROOT "$r" and "$f" in same process} if $r ne $f;
    }else{
        my $lib = "$r/lib";
        unshift @::INC, $lib if !grep{ $_ eq $lib } @::INC;
    }
    #$Flapp::UTF8 = 1;
    #binmode $_, ':utf8' for (*STDOUT, *STDERR, *STDIN);
}

use Flapp qw/-b MyProject::Object -i Flapp -m -r -s -w/;

1;
