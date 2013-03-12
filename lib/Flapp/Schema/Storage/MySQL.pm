package Flapp::Schema::Storage::MySQL;
use Flapp qw/-b Flapp::Schema::Storage -m -r -s -w/;

sub deflate_date { $_[1]->ymd }

sub deflate_time { $_[1]->ymd.' '.$_[1]->hms }

sub disable_constraint_sql { "SET foreign_key_checks=0;\n" }

sub enable_constraint_sql { "SET foreign_key_checks=1;\n" }

sub insert {
    my($self, $row, $_org, $_txn, $opt) = @_;
    shift->SUPER::insert(@_);
    my $cn = $row->_global_->{-mysql_a};
    if($cn && !defined $_org->{$cn}){
        my $dbh = $self->dbh->master;
        my $id = $dbh->FETCH('mysql_insertid') || die;
        $row->set_column($cn, $_org->{$cn} = $id);
        
        my $pool = $dbh->FETCH('private_flapp_dbh')->[0];
        if(my $txl = $pool->{txl}){
            my $p = $txl->{p} || die;
            $txl->{p} = $p->[3] ||= do{
                $p->[0] =~ /^INSERT INTO (\S+) \((.*)\) VALUES \((.*)\)\z/ || die $p->[0];
                my $s = $2 ne '' && ', ';
                $pool->_txl_prepare("INSERT INTO $1 ($cn$s$2) VALUES (?$s$3)");
            };
            my $i = $dbh->FETCH('AutoCommit') ? 1 : 2;
            my $x = pop @{$p->[$i]} || die;
            push @{$txl->{p}[$i]}, $x;
            substr($$x, index($$x, ':') + 1, 0) = "\t$id";
        }
    }
    1;
}

sub on_add_column {
    my($self, $sch, $ci) = @_;
    $ci->{-a} = $ci->{-u} = 1 if $ci->{-t} eq 'serial';
    $sch->_global_->{-mysql_a} = $ci->{name} if $ci->{-a};
    shift->SUPER::on_add_column(@_);
}

sub typeof {
    my($self, $ci) = @_;
    my $t = $ci->{-t};
    $t eq 'date' ? 'date' :
    ($t eq 'datetime' || $t eq 'timestamp') ? 'time' :
    ($t =~ /char|text/) ? 'str' :
    ($t =~ /int/ || $t eq 'decimal' && ($ci->{-s} || 0) =~ /^[0-9]+\z/) ? 'int' :
    '?';
}

1;
