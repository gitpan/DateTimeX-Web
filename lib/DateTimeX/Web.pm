package DateTimeX::Web;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use DateTime;
use DateTime::Locale;
use DateTime::TimeZone;
use DateTime::Format::Strptime;
use DateTime::Format::Mail;
use DateTime::Format::W3CDTF;
use DateTime::Format::MySQL;

sub new {
  my $class = shift;

  my %config = ( @_ == 1 && ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  $config{on_error} ||= 'croak';

  my $self = bless {
    config => \%config,
    format => {
      mail  => DateTime::Format::Mail->new( loose => 1 ),
      wwwc  => DateTime::Format::W3CDTF->new,
      mysql => DateTime::Format::MySQL->new,
    },
    parser => {},
  }, $class;

  $self->time_zone( $config{time_zone} || delete $config{timezone} || 'UTC' );
  $self->locale( $config{locale} || 'en_us' );

  $self;
}

sub format {
  my ($self, $name, $package) = @_;

  if ( $package ) {
    if ( ref $package ) {
      $self->{format}->{lc $name} = $package;
    }
    else {
      unless ( $package =~ s/^\+// ) {
        $package =~ s/^DateTime::Format:://;
        $package = "DateTime::Format\::$package";
      }
      eval "require $package;";
      croak $@ if $@;
      $self->{format}->{lc $name} = $package->new;
    }
  }
  $self->{format}->{lc $name};
}

sub time_zone {
  my ($self, $zone) = @_;

  if ( $zone ) {
    $self->{config}->{time_zone} = $zone->isa('DateTime::TimeZone')
      ? $zone
      : DateTime::TimeZone->new( name => $zone );
  }
  $self->{config}->{time_zone};
}

sub locale {
  my ($self, $locale) = @_;

  if ( $locale ) {
    $self->{config}->{locale} = $locale->isa('DateTime::Locale::root')
      ? $locale
      : DateTime::Locale->load( $locale );
  }
  $self->{config}->{locale};
}

sub now {
  my ($self, %options) = @_;

  $self->_merge_config( \%options );

  my $dt = eval { DateTime->now( %options ) };
  $self->_error( $@ ) if $@;
  return $dt;
}

sub from {
  my ($self, %options) = @_;

  return $self->from_epoch( %options ) if $options{epoch};

  $self->_merge_config( \%options );

  my $dt = eval { DateTime->new( %options ) };
  $self->_error( $@ ) if $@;
  return $dt;
}

sub from_epoch {
  my $self  = shift;
  my $epoch = shift;
     $epoch = shift if $epoch eq 'epoch';
  my %options = @_;

  $self->_merge_config( \%options );

  my $dt = eval { DateTime->from_epoch( epoch => $epoch, %options ) };
  $self->_error( $@ ) if $@;

  return $dt;
}

sub from_rss   { shift->parse_as( wwwc  => @_ ); }
sub from_mail  { shift->parse_as( mail  => @_ ); }
sub from_mysql { shift->parse_as( mysql => @_ ); }

*from_wwwc = \&from_rss;

sub parse_as {
  my ($self, $formatter, $string, %options) = @_;

  $self->_load( $formatter );

  my $dt = eval { $self->format($formatter)->parse_datetime( $string ) };
  if ( $@ ) {
    $self->_error( $@ );
  }
  else {
    $self->_merge_config( \%options );
    $self->_set_config( $dt, \%options );
    return $dt;
  }
}

sub parse {
  my ($self, $pattern, $string, %options) = @_;

  unless ( $self->{parser}->{$pattern} ) {
    $self->_merge_config( \%options );
    $options{pattern} = $pattern;
    my $parser = DateTime::Format::Strptime->new( %options );
    $self->{parser}->{$pattern} = $parser;
  }
  my $dt = eval { $self->{parser}->{$pattern}->parse_datetime( $string ) };
  if ( $@ ) {
    $self->_error( $@ );
  }
  else {
    $self->_set_config( $dt, \%options );
    return $dt;
  }
}

*strptime = \&parse;

sub for_rss   { shift->render_as( wwwc  => @_ ); }
sub for_mail  { shift->render_as( mail  => @_ ); }
sub for_mysql { shift->render_as( mysql => @_ ); }

*for_wwwc = \&for_rss;

sub render_as {
  my ($self, $formatter, @args) = @_;

  $self->_load( $formatter );

  my $dt = $self->_datetime( @args );

  my $str = eval { $self->format($formatter)->format_datetime( $dt ) };
  $self->_error( $@ ) if $@;
  return $str;
}

sub _merge_config {
  my ($self, $options) = @_;

  foreach my $key (qw( time_zone locale )) {
    next unless defined $self->{config}->{$key};
    next if defined $options->{$key};
    $options->{$key} = $self->{config}->{$key};
  }
}

sub _datetime {
  my $self = shift;

  return $self->now unless @_;
  return $_[0] if @_ == 1 && $_[0]->isa('DateTime');
  return $self->from( @_ );
}

sub _load {
  my ($self, $formatter) = @_;

  unless ( $self->format($formatter) ) {
    $self->format( $formatter => "DateTime::Format\::$formatter" );
  }
}

sub _set_config {
  my ($self, $dt, $options) = @_;

  $options ||= $self->{config};

  foreach my $key (qw( time_zone locale )) {
    my $func = "set_$key";
    $dt->$func( $options->{$key} ) if $options->{$key};
  }
}

sub _error {
  my ($self, $message) = @_;

  my $on_error = $self->{config}->{on_error};

  return if $on_error eq 'ignore';
  return $on_error->( $message ) if ref $on_error eq 'CODE';

  local $Carp::CarpLevel = 1;
  croak $message;
}

1;

__END__

=head1 NAME

DateTimeX::Web - DateTime factory for web apps

=head1 SYNOPSIS

  use DateTimeX::Web

  # create a factory.
  my $dtx = DateTimeX::Web->new(time_zone => 'Asia/Tokyo');

  # then, grab a DateTime object from there.
  my $obj = $dtx->now;

  # with arguments for a DateTime constructor.
  my $obj = $dtx->from(year => 2008, month => 2, day => 9);

  # or with epoch (you don't need 'epoch =>' as it's obvious).
  my $obj = $dtx->from_epoch(time);

  # or with a WWWC datetime format string.
  my $obj = $dtx->from_rss('2008-02-09T01:00:02');

  # actually you can use any Format plugins.
  my $obj = $dtx->parse_as(MySQL => '2008-02-09 01:00:02');

  # of course you may need to parse with strptime.
  my $obj = $dtx->parse('%Y-%m-%d', $string);

  # you may want to create a datetime string for RSS.
  my $str = $dtx->for_rss;

  # or for emails (you can pass an arbitrary DateTime object).
  my $str = $dtx->for_mail($dt);

  # or for database (with arguments for a DateTime constructor).
  my $str = $dtx->for_mysql(year => 2007, month => 3, day => 3);

  # actually you can use any Format plugins.
  my $str = $dtx->render_as(MySQL => $dt);

  # you want finer control?
  my $str = $dtx->format('mysql')->format_date($dt);

=head1 DESCRIPTION

The DateTime framework is quite useful and complete. However, sometimes it's a bit too strict and cumbersome. Also, we usually need to load too many common DateTime components when we build a web application. That's not DRY.

So, here's a factory to make it sweet. If you want more chocolate or cream, help yourself. The DateTime framework boasts a variety of flavors.

=head1 METHODS

=head2 new

creates a factory object. If you pass a hash, or a hash reference, it will be passed to a DateTime constructor. You usually want to provide a sane "time_zone" option.

Optionally, you can pass an "on_error" option ("ignore"/"croak"/some code reference) to the constructor. DateTimeX::Web croaks by default when DateTime spits an error. If "ignore" is set, DateTimeX::Web would ignore the error and return undef. If you want finer control, provide a code reference.

=head2 format

takes a formatter's base name and returns the corresponding DateTime::Format:: object. You can pass an optional formatter package name/object to replace the previous formatter (or to add a new one).

=head2 time_zone, locale

returns the current time zone/locale object of the factory, which would be passed to every DateTime object it creates. You can pass an optional time zone/locale string/object to replace.

=head1 METHODS TO GET A DATETIME OBJECT

=head2 now, from_epoch

returns a DateTime object as you expect.

=head2 from

takes arguments for a DateTime constructor and returns a DateTime object. Also, You can pass (epoch => time) pair for convenience.

=head2 from_rss, from_wwwc

takes a W3CDTF (ISO 8601) datetime string used by RSS 1.0 etc, and returns a DateTime object.

=head2 from_mail

takes a RFC2822 compliant datetime string used by email, and returns a DateTime object.

=head2 from_mysql

takes a MySQL datetime string, and returns a DateTime object. 

=head2 parse_as

takes a name of DateTime::Format plugin and some arguments for it, and returns a DateTime object.

=head2 parse, strptime

takes a strptime format string and a datetime string, and returns a DateTime object.

=head1 METHODS TO GET A DATETIME STRING

=head2 for_rss, for_wwwc

may or may not take a DateTime object (or arguments for a DateTime constructor), and returns a W3CDTF datetime string.

=head2 for_mail

the same as above but returns a RFC2822 datetime string.

=head2 for_mysql

the same as above but returns a MySQL datetime string.

=head2 render_as

takes a name of DateTime::Format plugin and the same thing(s) as above, and returns a formatted string.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Format::Mail>, L<DateTime::Format::MySQL>, L<DateTime::Format::W3CDFT>, L<DateTime::Format::Strptime>, L<DateTime::TimeZone>, L<DateTime::Locale>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
