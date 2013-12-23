##!perl -T
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Find;

#TODO: Think about abstracting $ENV{XXX} usage via $app->env
# so we can run under -T switch. Disable -T switch because of Mojo till then.
#$ENV{MOJO_BASE_DEBUG}=0;
my @files;
find(
    {   wanted => sub { /\.pm$/ and push @files, $_ },
        no_chdir => 1
    },
    -e 'blib' ? 'blib' : 'lib',
);

for my $file (@files) {
    my $module = $file;
    ok($module,$module);
    $module =~ s,\.pm$,,;
    $module =~ s,.*/?lib/,,;
    $module =~ s,/,::,g;

    use_ok($module) || diag $@;
}
isa_ok('Ado::Plugin::Mess','Ado::Plugin');

for ( qw(register config name app))
{
    can_ok('Ado::Plugin::Mess', $_);
}

isa_ok('Ado::Control::Mess','Ado::Control');

for ( qw(list add update show disable))
{
    can_ok('Ado::Control::Mess', $_);
}


diag("Testing loading of Ado $Ado::Plugin::Mess::VERSION, Perl $], $^X");

done_testing();
