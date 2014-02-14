# Class: Bugov::Common::Controller::Admin::Abstract
#   Abstract class for admin controllers.
# Extends:
#   Mojolicious::Controller

package Bugov::Common::Controller::Admin::Abstract;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util;

has 'module';
has 'model_name';
has 'size' => 20;

# Caching generated values.
has '_model' => undef;
has '_method' => undef;

# Method: list
#   List of something. $size is a SQL limit.
sub list {
  my $self = shift;
  my $page = int $self->param('page');
  my ($model, $method) = $self->_get_model();
  my ($manager, $get, $get_count) = ("${model}::Manager", "get_$method", "get_${method}_count");
  
  my $list = $manager->$get(sort_by => 'id', limit => $self->size, offset => $self->size * ($page-1));
  my $count = $manager->$get_count;
  
  $self->render(Mojo::Util::decamelize($self->model_name) . '/admin/list',
    list => $list, count => $count, limit => $self->size);
}

# Method: show
#   Show one something for editing.
sub show {
  my $self = shift;
  my ($model) = $self->_get_model();

  my $item = $model->new(id => int $self->param('id'))->load;
  $self->render(Mojo::Util::decamelize($self->model_name) . '/admin/form', item => $item);
}

# Method: edit
#   Edit one something. Don't show form, just edit.
sub edit {
  my $self = shift;
  my ($model) = $self->_get_model();
  
  my $item = $model->new(id => int $self->param('id'))->load;
  $self->_dehydrate($item);
  $item->save;
  
  my $message = Mojo::Util::camelize($self->model_name) . ' edited';
  my $name = Mojo::Util::decamelize($self->model_name);
  $self->flash({message => $message, type => 'success'})
    ->redirect_to("admin_${name}_show", id => $item->id);
}

# Method: create
#   Create one something. Just create.
sub create {
  my $self = shift;
  my ($model, $method) = $self->_get_model();
  
  my $item = $model->new();
  $self->_dehydrate($item);
  $item->save;
  
  my $message = Mojo::Util::camelize($self->model_name) . ' created';
  my $name = Mojo::Util::decamelize($self->model_name);
  $self->flash({message => $message, type => 'success'})
    ->redirect_to("admin_${name}_show", id => $item->id);
}

# Method: delete
#   Delete one something. Just delete.
sub delete {
  my $self = shift;
  my ($model) = $self->_get_model();
  eval { $model->new(id => int $self->param('id'))->delete };
  
  my $message = Mojo::Util::camelize($self->model_name) . ' deleted';
  my $name = Mojo::Util::decamelize($self->model_name);
  $self->flash({message => $message, type => 'success'})
    ->redirect_to("admin_${name}_list");
}

# Method: _get_model
#   Get model and method's infix.
# Parameters:
#   $self->model_name
# Returns:
#   $model - Str
#   $method - Str
sub _get_model {
  my $self = shift;
  
  # Return from "cache"
  return ($self->_model, $self->_method) if $self->_model && $self->_method;
  
  # Generate
  my $model = $self->module . '::Model::' . Mojo::Util::camelize($self->model_name);
  my $method = Mojo::Util::decamelize($self->model_name);
  
  if ($method =~ /y$/) {
    chop $method;
    $method .='ies';
  }
  elsif ($method =~ /s$/) {
    $method .= 'es';
  } else {
    $method .= 's';
  }
  
  $self->_model($model);
  $self->_method($method);
  
  return ($model, $method);
}

# Method: _dehydrate
#   Redefine if you wanna custom work with input.
sub _dehydrate {
  my ($self, $item) = @_;
  my ($model) = $self->_get_model();
  $item->$_($self->param($_)) for keys %{ $model->to_h };
}

1;

__END__

=pod

=head1 NAME

Bugov::Common::Controller::Admin::Abstract - admin panel abstract controller.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Georgy Bazhukov <georgy.bazhukov@gmail.com>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
