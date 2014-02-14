package Bugov::Common;
use Mojo::Base 'Mojolicious::Plugin::Module::Abstract';
use DateTime;
use DateTime::Format::MySQL;
use DateTime::Format::HTTP;
use Mojo::ByteStream;

sub startup {
  my ($self, $app) = @_;
  no strict;
  $::app = $app;
}

sub init_helpers {
  my ($self, $app) = @_;
  
  # Helper: dt
  #   Format datetime
  # Parameters:
  #   time - Str|Int
  #   format - Undef|Str
  # Return:
  #   Int|Str
  $app->helper(dt => sub {
    my ($self, $time, $format) = @_;
    
    my $reformat = sub {
      my ($dt, $fmt) = @_;
      
      given ($fmt) {
        when ('dd.mm.yy') {
          my $d = $dt->day   < 10 ? '0'.$dt->day   : $dt->day;
          my $m = $dt->month < 10 ? '0'.$dt->month : $dt->month;
          my $y = substr $dt->year, 2;
          return "$d.$m.$y";
        }
        when ('GMT') {
          DateTime::Format::HTTP->format_datetime($dt);
        }
        default { return "Invalid format" }
      }
    };
    
    # current time
    if (!defined $time) {
      my $dt = DateTime->now();
      return ( $format
        ? $reformat->($dt, $format)
        : DateTime::Format::MySQL->format_datetime($dt) );
    }
    # show time
    elsif ($time =~ /^\d+$/) {
      my $dt = DateTime->from_epoch(epoch => $time);
      return ( $format
        ? $reformat->($dt, $format)
        : DateTime::Format::MySQL->format_datetime($dt) );
    }
    # get time from string
    elsif ($time =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) {
      my $dt = DateTime::Format::MySQL->parse_datetime($time);
      return $dt->epoch();
    }
  });
  
  # Helper: paginator
  #   Paginator (what do you expect to see here?)
  # Parameters:
  #   self        Mojolicious::Controller (I thought)
  #   url_name    Str Mojolicious::Routes::Route's name
  #   cur         Int current page number
  #   count       Int count of items
  #   size        Int like sql limit
  #   params      ArrayRef Mojolicious::Routes::Route's  params
  # Return: Mojo::ByteStream paginator's html
  $app->helper(paginator => sub {
    my ($self, $url_name, $cur, $count, $size, $params) = @_;
    my $html = '';
    return '' if not defined $count or $count <= $size;
    
    my $last = int ( $count / $size );
    ++$last if $count % $size;
    
    # Render first page.
    $html .= sprintf '<a href="%s">&laquo;</a>',
      $self->url_for($url_name, page => 1) if $cur != 1;
    
    for my $i ($cur-5 .. $cur+5) {
      next if $i < 1 || $i > $last;
      $params = [] unless defined $params;
      $html .= ($i == $cur ? sprintf '<span>%s</span>', $cur :
        sprintf '<a href="%s">%s</a>', $self->url_for($url_name, @$params, page => $i), $i);
    }
    
    # Render last page.
    $html .= sprintf '<a href="%s">&raquo;</a>',
      $self->url_for($url_name, page => $last) if $cur != $last;
    Mojo::ByteStream->new("<div class=\"paginator\">$html</div>");
  });
  
  # Simple helpers:
  $app->helper(error_json => sub { $_[0]->render(json => {status => 500, @_[1..$#_]}) });
  $app->helper(not_found => sub { shift->render(template => 'not_found', status => 404) });
  $app->helper(not_found_json => sub { shift->render(json => {error => 404, status => 404, 'message' => 'Page not found'}) });
  $app->helper(crlf => sub { $_[1] =~ s/</&lt;/g; $_[1] =~ s/>/&gt;/g; $_[1] =~ s/\r?\n/<br>/g; Mojo::ByteStream->new($_[1])});
  $app->helper(b => sub { Mojo::ByteStream->new($_[1]) });
  $app->helper(translit => sub { rus_to_lat_url($_[1]) });
}

sub rus_to_lat_url {
  my $s = shift;
  $s =~ s/(?:^\s+|\s+$)//g;
  $s =~ s/А/a/ig;
  $s =~ s/Б/b/ig;
  $s =~ s/В/v/ig;
  $s =~ s/Г/g/ig;
  $s =~ s/Д/d/ig;
  $s =~ s/Е/e/ig;
  $s =~ s/Ё/jo/ig;
  $s =~ s/Ж/zh/ig;
  $s =~ s/З/z/ig;
  $s =~ s/И/i/ig;
  $s =~ s/К/k/ig;
  $s =~ s/Л/l/ig;
  $s =~ s/М/m/ig;
  $s =~ s/Н/n/ig;
  $s =~ s/О/o/ig;
  $s =~ s/П/p/ig;
  $s =~ s/Р/r/ig;
  $s =~ s/С/s/ig;
  $s =~ s/Т/t/ig;
  $s =~ s/У/u/ig;
  $s =~ s/Ф/f/ig;
  $s =~ s/Х/h/ig;
  $s =~ s/Ц/c/ig;
  $s =~ s/Ч/ch/ig;
  $s =~ s/Щ/sch/ig;
  $s =~ s/Ш/sh/ig;
  $s =~ s/Ы/y/ig;
  $s =~ s/Э/e/ig;
  $s =~ s/Ю/ju/ig;
  $s =~ s/Я/ja/ig;
  $s =~ s/\s+/-/g;
  $s =~ s/[^0-9a-zA-Z\-]//g;
  $s =~ s/-+/-/g;
  lc $s;
}

1;