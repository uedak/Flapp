package Flapp::App::Web::Controller::FlappDeveloperSupport::CrudExample2;
use Flapp qw/-b Flapp::App::Web::Controller -m -s -w/;

sub _is_valid {
    my($self, $row) = @_;
    $row->validate
        ->validate_related('entry_members')
        ->validate_related('content')
        ->errors->is_empty;
}

sub _set_columns { #U/Iとデータの差異を吸収
    my($self, $p, $row) = @_;
    my %d = %$p; #don't modify params
    $d{category_id} ||= undef;
    $row->set_columns(\%d);
    $row->category({name => $d{new_category_name}}) if $d{new_category_name};
    $row->entry_members($d{entry_members}, {-i => [qw/member_id/]})
        ->content($d{content}, {-i => []});
    $row->members; #prefetch by many_to_many
    $self;
}

sub _set_params { #データとU/Iの差異を吸収
    my($self, $row, $p) = @_;
    %$p = %{$row->get_columns({entry_members => {}, content => {}})};
    my $cat = $row->category;
    $p->{new_category_name} = $cat->name if $cat && !$cat->in_storage;
    $self;
}

sub _save {
    my($self, $row) = @_;
    $row->txn_do(sub{
        $row->category->save if $row->category;
        $row->save
            ->save_related(entry_members => {-d => 1})
            ->content->save;
    });
}

sub _schema { shift->project->schema->ExampleEntry }

sub delete :Action(id){
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    $row->txn_do(sub{
        $row->entry_members([])->save_related(entry_members => {-d => 1})
            ->content(undef)->save_related(content => {-d => 1})
            ->delete;
    });
    $c->flash(notice => '削除しました')->redirect_for('../');
}

sub edit :Action(id) {
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    my $p = $c->inflate_params($c->req->params);
    
    if($c->submit_by('.confirm')){
        if($self->_set_columns($p => $row)->_is_valid($row)){
            $c->session->set($self->PATH, $p);
            return $c->redirect_for('../edit_confirm/'.$row->id);
        }
    }elsif($p->{'.back'} && (my $p = $c->session->get($self->PATH))){
        $self->_set_columns($p => $row)->_is_valid($row);
    }
    
    $self->_set_params($row => $c->req->params); #for fillinform
    $c->stash(row => $row);
}

sub edit_confirm :Action(id) {
    my($self, $c) = @_;
    my $row = $self->_schema->find($c->args->{id}) || return $c->http_error(404);
    my $p = $c->session->get($self->PATH);
    
    if(!$p || !$self->_set_columns($p => $row)->_is_valid($row)){
        return $c->redirect_for('../edit/'.$row->id, {'.back' => 1});
    }elsif($c->submit_by('.update')){
        $self->_save($row);
        $c->session->remove($self->PATH);
        return $c->flash(notice => '変更しました')->redirect_for('../');
    }
    
    $c->stash(row => $row);
}

sub index :Action {
    my($self, $c) = @_;
    my $p = $c->req->params;
    my($rows, $pager) = $self->_schema->search([], {
        select   => [qw/me.title category.name entry_members.priv_cd member.name/],
        join     => {category => {}, entry_members => {member => {}}},
        order_by => [qw/me.id/],
        rows     => 5,
        page     => ($p->{page} || 1),
    });
    $c->stash(rows => $rows, pager => $pager);
}

sub new :Action {
    my($self, $c) = @_;
    my $row = $self->_schema->new;
    my $p = $c->inflate_params($c->req->params);
    
    if($c->submit_by('.confirm')){
        if($self->_set_columns($p => $row)->_is_valid($row)){
            $c->session->set($self->PATH, $p);
            return $c->redirect_for('new_confirm');
        }
    }elsif($p->{'.back'} && (my $p = $c->session->get($self->PATH))){
        $self->_set_columns($p => $row)->_is_valid($row);
    }
    
    $self->_set_params($row => $c->req->params); #for fillinform
    $c->stash(row => $row);
}

sub new_confirm :Action {
    my($self, $c) = @_;
    my $row = $self->_schema->new;
    my $p = $c->session->get($self->PATH);
    
    if(!$p || !$self->_set_columns($p => $row)->_is_valid($row)){
        return $c->redirect_for('new', {'.back' => 1});
    }elsif($c->submit_by('.create')){
        $self->_save($row);
        $c->session->remove($self->PATH);
        return $c->flash(notice => '登録しました')->redirect_for('./');
    }
    
    $c->stash(row => $row);
}

sub select_member :Action {
    my($self, $c) = @_;
    my $p = $c->req->params;
    my($rows, $pager) = $self->_schema->ExampleMember
        ->search([], {order_by => 'id', rows => 5, page => ($p->{page} || 1)});
    $c->stash(rows => $rows, pager => $pager);
}

1;
