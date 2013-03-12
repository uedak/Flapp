package Flapp::App::Cmd::Tool::Controller::Root;
use Flapp qw/-b Flapp::App::Cmd::Controller -m -s -w/;

sub console :Action {
    my($self, $c) = @_;
    $c->OS->unlink($c->pid_file);
    print '# Loading '.$c->project->env." environment. (Ctrl+D for exec)\n";
    $c->OS->console;
}

sub generate :Action {
    my($self, $c) = @_;
    my $proj = $c->project;
    my $dir = $c->project_root.'/generate';
    my $ls = $proj->OS->ls($dir) || die "$!($dir)";
    my $ss = join(' or ', map{ substr($_, 2) } @$ls);
    my $u = 'usage: run.pl generate SOURCE NAME [PATH]';
    
    my($src, $name, $dst) = @{$c->argv};
    die "No SOURCE($ss)\n$u" if !$src;
    die qq{Invalid SOURCE: "$src" ($ss)\n$u} if !grep{ $_ eq "My$src" } @$ls;
    die "No NAME\n$u\n" if !$name;
    
    $dst ||= $src eq 'Project' ? $name : $c->project_root."/apps/$name";
    $proj->generate("My$src", $name, $dst);
    
    if($src eq 'Project'){
        my $pm = "$dst/lib/$name.pm";
        $proj->OS->cat(my $buf, '<', $pm) || die "$!($pm)";
        my $root = '__'.uc($proj).'_ROOT__';
        $buf =~ s/$root/$proj->root_dir/e;
        $proj->OS->cat($buf, '>', $pm) || die "$!($pm)";
    }
}

sub verify_inheritance :Action {
    my($self, $c) = @_;
    require Flapp::Core::Include;
    &Flapp::Core::Include::isa_of($c->project => my $i = []);
    @$i = ($c->project, reverse @$i);
    
    require File::Find;
    my $cnt;
    while((my $i1 = shift(@$i)) && (my $i2 = $i->[0])){
        my $d1 = $i1->root_dir.'/lib';
        my $d2 = $i2->root_dir.'/lib';
        my $m = qr%^\Q$d2/$i2\E(.*/[A-Z][0-9A-Za-z]*\.pm)\z%;
        &File::Find::find({
            no_chdir => 1,
            wanted => sub{
                $_ =~ $m || return;
                my $pm = substr($1, 1);
                return if $pm =~ m%^(
                    Core\b|DBI\.
                    |App/Cmd/Tool/Controller/
                    |App/Web/Controller/FlappDeveloperSupport\b
                    |Schema/Core/
                    |Template/Directive/
                )%x || -f "$d1/$i1/$pm";
                print qq{No "$i1/$pm" for $i2\n};
                $cnt++;
            },
        }, $d2);
    }
    print "Inheritance is ok\n" if !$cnt;
}

1;
