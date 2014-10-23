use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

my $dtx = DateTimeX::Web->new(
  time_zone => 'UTC',
  on_error  => 'ignore'
);

my %args = (
  year   => 2003,
  month  => 3,
  day    => 10,
  hour   => 15,
  minute => 49,
  second => 17,
);

my $http_datetime = "Mon, 10 Mar 2003 15:49:17 GMT";

{
  my $dt = $dtx->from_http($http_datetime);

  ok defined $dt;
  is $dt->year   => $args{year};
  is $dt->month  => $args{month};
  is $dt->day    => $args{day};
  is $dt->hour   => $args{hour};
  is $dt->minute => $args{minute};
  is $dt->second => $args{second};
  is $dt->time_zone->name => 'UTC';
}

{
  my $dt = $dtx->from_http('Mon, 66 Mar 2003 15:49:17');
  ok !defined $dt;
}

{
  my $str = $dtx->for_http( %args );
  is $str => $http_datetime;
}
