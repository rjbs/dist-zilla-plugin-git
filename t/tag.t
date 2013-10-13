#!perl

use strict;
use warnings;

use Cwd qw( cwd );
use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::Temp qw{ tempdir };
use Git::Wrapper;
use Path::Class;
use Test::More   tests => 4;

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );
my $cwd = cwd();
END { chdir $cwd if $cwd }
# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/tag')->absolute,
});

chdir $zilla->tempdir->subdir('source');
system "git init";
my $git = Git::Wrapper->new('.');

$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# do the release
$zilla->release;

# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );
is( $tags[0], $zilla->plugin_named('Git::Tag')->tag(), 'new tag matches the tag the plugin claims is the tag.');

# attempting to release again should fail
eval { $zilla->release };

like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');

