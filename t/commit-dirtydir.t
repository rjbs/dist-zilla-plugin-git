#!perl

use strict;
use warnings;

use Cwd qw( cwd );
use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Git::Wrapper;
use Path::Class;
use File::Temp qw/tempdir/;
use lib 't/lib';
use Test::More   tests => 3;

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );
my $cwd = cwd();
END { chdir $cwd if $cwd }

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/commit-dirtydir')->absolute,
});

chdir $zilla->tempdir->subdir('source');
system "git init";
my $git = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# do a release, with changes and dist.ini updated
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
$zilla->release;

# check if dist.ini and changelog have been committed
my ($log) = $git->log( 'HEAD' );
like( $log->message, qr/v1.23\n[^a-z]*foo[^a-z]*bar[^a-z]*baz/, 'commit message taken from changelog' );

# check if we committed our tarball
my @files = $git->ls_files( { cached => 1 } );
ok( ( grep { $_ =~ /releases/ } @files ), "We committed the tarball" );

# We should have no dirty files uncommitted
# ignore the "DZP-git.9y5u" temp file, ha!
@files = $git->ls_files( { others => 1, modified => 1, unmerged => 1 } );
ok( @files == 1, "No untracked files left" );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}

