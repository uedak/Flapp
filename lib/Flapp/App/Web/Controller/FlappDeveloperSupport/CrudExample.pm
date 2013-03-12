package Flapp::App::Web::Controller::FlappDeveloperSupport::CrudExample;
use Flapp qw/-b Flapp::App::Web::Controller -m -s -w/;

sub _auto {
    my($self, $c) = @_;
    
    eval{ $self->_schema->find(0) };
    my $msg;
    if($@ =~ /^Can't locate object method "ExampleMember"/){
        $msg = "Schema::Default::ExampleMember が存在しません。\n";
    }elsif($@ =~ /^Unknown database/){
        $msg = "データベースが作成されていません。\n".
            $c->project_root."/apps/Tool/run.pl DB::show_create_database_sql\n".
            "で表示されるSQLを実行して下さい。\n";
    }elsif($@ =~ /Table .+ doesn't exist/){
        $msg = "テーブルが存在しません。\n".
            $c->project_root."/apps/Tool/run.pl DB::create_ddl\n".
            $c->project_root."/apps/Tool/run.pl DB::migrate\n".
            "を実行して下さい。\n";
    }elsif($@){
        die $@;
    }
    if($msg){
        $c->res->content_type('text/plain; charset=UTF-8;');
        $c->res->body($msg);
        return !1;
    }
    
    $c->project->dbh->txn_log( #txn log sample
        $c->app_name.':'.($c->session->get('uid') || '?').'@'.$c->req->path,
        'txn-sample',
    );
    
    #my $sch = $c->project->schema;
    #$c->project->schema_cache->{$sch} = {map{ $_ => {} } @{$sch->_schema_names_}};
    
    1;
}

use constant SPLIT_INPUTS => [
    [qw/email    @ 2/],
    [qw/birthday - 3/],
    [qw/tel      - 3/],
];

sub _params2row { #U/Iとデータの差異を吸収
    my($self, $p, $row) = @_;
    my %d = %$p; #don't modify params
    $self->_join_($p => \%d, @{$self->SPLIT_INPUTS});
    $d{hobbies} = [$p->get_all('hobbies')];
    
    $d{$_} && $self->Util->tr(\($d{$_}), 'asc_z2h', 1) for qw/
        email birthday tel money
    /;
    $row->set_columns(\%d);
    $self;
}

sub _row2params { #データとU/Iの差異を吸収
    my($self, $row, $p) = @_;
    %$p = %{$row->get_columns};
    $self->_split_($p => $p, @{$self->SPLIT_INPUTS});
    $self;
}

sub _schema { shift->project->schema->ExampleMember }

sub delete :Action(id){
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    $row->txn_do(sub{
        $row->entry_members([])
            ->save_related('entry_members', {-d => 1})
            ->delete;
    });
    $c->flash(notice => '削除しました')->redirect_for('../');
}

sub edit :Action(id) {
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    my $p = $c->req->params;
    
    if($c->submit_by('.confirm')){
        if($self->_params2row($p => $row) && $row->is_valid){
            $c->session->set($self->PATH => $p);
            return $c->redirect_for('../edit_confirm/'.$row->id);
        }
    }elsif($p->{'.back'} && (my $p = $c->session->get($self->PATH))){
        $self->_params2row($p => $row);
    }
    
    $self->_row2params($row => $c->req->params); #for fillinform
    $c->stash(row => $row);
}

sub edit_confirm :Action(id) {
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    my $p = $c->session->get($self->PATH);
    
    if(!$p || !$self->_params2row($p => $row) || !$row->is_valid){
        return $c->redirect_for('../edit/'.$row->id);
    }elsif($c->submit_by('.update')){
        $row->save;
        $c->session->remove($self->PATH);
        return $c->flash(notice => '変更しました')->redirect_for('../');
    }
    
    $c->stash(row => $row);
}

sub index :Action {
    my($self, $c) = @_;
    my $p = $c->req->params;
    my $k = $self->PATH.'search'; #session key
    my $s = $c->session->get($k) || {};
    if(delete $p->{'.search'}){
        $s = {%$p, hobbies => [$p->get_all('hobbies')], page => 1};
        $c->session->set($k => $s);
    }elsif($p->{page}){
        $s->{page} = $p->{page};
        $c->session->set($k => $s);
    }
    %$p = %$s; #fillinform
    
    my @q;
    push @q, ['name LIKE ?', "%$s->{name}%"] if defined $s->{name} && $s->{name} ne '';
    if(@{$s->{hobbies} || []}){
        push @q, my $h = [];
        foreach(@{$s->{hobbies}}){
            push @$h, '-or' if @$h;
            push @$h, ['hobbies LIKE ?', "%:$_:%"];
        }
    }
    
    my($rows, $pager) = $self->_schema->search(\@q,
        {order_by => 'id', rows => 5, page => ($s->{page} || 1)});
    $c->stash(rows => $rows, pager => $pager);
}

sub new :Action {
    my($self, $c) = @_;
    my $row = $self->_schema->new;
    my $p = $c->req->params;
    
    if($c->submit_by('.confirm')){
        if($self->_params2row($p => $row) && $row->is_valid){
            $c->session->set($self->PATH => $p);
            return $c->redirect_for('new_confirm');
        }
    }elsif($p->{'.back'} && (my $p = $c->session->get($self->PATH))){
        $self->_params2row($p => $row);
    }
    
    $self->_row2params($row => $c->req->params); #for fillinform
    $c->stash(row => $row);
}

sub new_confirm :Action {
    my($self, $c) = @_;
    my $row = $self->_schema->new;
    my $p = $c->session->get($self->PATH);
    
    if(!$p || !$self->_params2row($p => $row) || !$row->is_valid){
        return $c->redirect_for('new');
    }elsif($c->submit_by('.create')){
        $row->save;
        $c->session->remove($self->PATH);
        return $c->flash(notice => '登録しました')->redirect_for('./');
    }
    
    $c->stash(row => $row);
}

1;
