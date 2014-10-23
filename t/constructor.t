use strict;
use warnings;
use Test::More qw(no_plan);
use DateTimeX::Web;

{ # by default, time_zone => UTC, locale => en_us
  my $dtx = DateTimeX::Web->new;

  ok $dtx->time_zone->isa('DateTime::TimeZone');
  is $dtx->time_zone->name => 'UTC';

  ok $dtx->locale->isa('DateTime::Locale::root');
  is $dtx->locale->name => 'English';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'UTC';
  is $dt->locale->name    => 'English';
}

{ # let's replace the time_zone and the locale (with other objects)
  my $dtx = DateTimeX::Web->new;

  $dtx->time_zone(DateTime::TimeZone->new( name => 'JST-9'));
  ok $dtx->time_zone->isa('DateTime::TimeZone');
  is $dtx->time_zone->name => 'Asia/Tokyo';

  $dtx->locale(DateTime::Locale->load('ja'));
  ok $dtx->locale->isa('DateTime::Locale::ja');
  is $dtx->locale->name => 'Japanese';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
  is $dt->locale->name    => 'Japanese';
}

{ # with other strings
  my $dtx = DateTimeX::Web->new;

  $dtx->time_zone('JST-9');
  ok $dtx->time_zone->isa('DateTime::TimeZone');
  is $dtx->time_zone->name => 'Asia/Tokyo';

  $dtx->locale('ja');
  ok $dtx->locale->isa('DateTime::Locale::ja');
  is $dtx->locale->name => 'Japanese';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
  is $dt->locale->name    => 'Japanese';
}

{ # provide a default time_zone
  my $dtx = DateTimeX::Web->new( time_zone => 'JST-9' );
  is $dtx->time_zone->name => 'Asia/Tokyo';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
}

{ # should accept a time_zone object, too.
  my $dtx = DateTimeX::Web->new( time_zone => DateTime::TimeZone->new( name => 'JST-9' ) );
  is $dtx->time_zone->name => 'Asia/Tokyo';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
}

{ # timezone should be ok
  my $dtx = DateTimeX::Web->new( timezone => 'JST-9' );
  is $dtx->time_zone->name => 'Asia/Tokyo';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
}

{ # provide a default locale
  my $dtx = DateTimeX::Web->new( locale => 'ja' );
  is $dtx->locale->name => 'Japanese';

  my $dt = $dtx->now;
  is $dt->locale->name => 'Japanese';
}

{ # should accept a locale object, too.
  my $dtx = DateTimeX::Web->new( locale => DateTime::Locale->load('ja') );
  is $dtx->locale->name => 'Japanese';

  my $dt = $dtx->now;
  is $dt->locale->name => 'Japanese';
}

{ # you can pass a hash reference
  my $dtx = DateTimeX::Web->new({ time_zone => 'JST-9', locale => 'ja' });

  ok $dtx->time_zone->isa('DateTime::TimeZone');
  is $dtx->time_zone->name => 'Asia/Tokyo';

  ok $dtx->locale->isa('DateTime::Locale::ja');
  is $dtx->locale->name => 'Japanese';

  my $dt = $dtx->now;
  is $dt->time_zone->name => 'Asia/Tokyo';
  is $dt->locale->name    => 'Japanese';
}

