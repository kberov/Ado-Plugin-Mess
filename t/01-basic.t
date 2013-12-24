use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catdir catfile);


my $NO_ADO_HOME = <<"NO";
$ENV{ADO_HOME} is not set! I hope you know what you are doing. Skipping this test....
NO
plan(skip_all => $NO_ADO_HOME) unless $ENV{ADO_HOME};
sub encode { Mojo::Util::encode $^O=~ /win/i ? 'cp866' : 'UTF-8', $_[0] }

$ENV{MOJO_MODE} = 'development';
($ENV{MOJO_HOME}) = abs_path(__FILE__) =~ m|^(.+)/[^/]+$|;
my @libs = (
    catdir($ENV{ADO_HOME}, 'site', 'lib'),
    catdir($ENV{ADO_HOME}, 'lib'),
    -e catdir($ENV{MOJO_HOME}, '..', 'blib')
    ? catdir($ENV{MOJO_HOME}, '..', 'blib')
    : catdir($ENV{MOJO_HOME}, '..', 'lib')
);

for my $d (@libs) {
    unshift @INC, $d if -d $d;
}
$ENV{MOJO_CONFIG} = catfile($ENV{MOJO_HOME}, 'etc', 'ado.conf');

my $t = Test::Mojo->new('Ado');
isa_ok($t->app, 'Ado');

#warn Data::Dumper::Dumper(\%INC);
ok($INC{'Ado/Plugin/Mess.pm'}, 'Ado::Plugin::Mess is loaded');

done_testing();

