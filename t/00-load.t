##!perl -T
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;
my $module = 'Ado::Plugin::Vest';
use_ok($module);
isa_ok('Ado::Plugin::Vest', 'Ado::Plugin');
for (qw(register config name app)) {
    can_ok('Ado::Plugin::Vest', $_);
}
use_ok('Ado::Control::Vest');
isa_ok('Ado::Control::Vest', 'Ado::Control');

for (qw(create update show disable screen)) {
    can_ok('Ado::Control::Vest', $_);
}

use_ok('Ado::Model::Vest');
isa_ok('Ado::Model::Vest', 'Ado::Model');

for (
    qw(is_base_class TABLE PRIMARY_KEY COLUMNS ALIASES CHECKS
    create _MESSAGES_SQL by_subject_message_id talks)
  )
{
    can_ok('Ado::Model::Vest', $_);
}

diag("Testing loading of Ado $Ado::Plugin::Vest::VERSION, Perl $], $^X");

done_testing();
