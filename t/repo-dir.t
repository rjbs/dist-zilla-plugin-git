#!perl

use strict;
use warnings;

use Cwd qw( cwd );
use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::Temp qw{ tempdir };
use Git::Wrapper;
use Path::Class;
use File::Copy 'move';
use Test::More   tests => 1;

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );
my $cwd = cwd();
END { chdir $cwd if $cwd }

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/repo-dir')->absolute,
});

chdir $zilla->tempdir->subdir( 'source' );

system "git init";
my $git = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );

mkdir 'dist';

# move corpus files to subdir of git repo
move 'dist.ini', 'dist/dist.ini';
move 'Changes', 'dist/Changes';

# do a release in a subdir; the git repo is one level up
chdir 'dist';

$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );


append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");


# create a new zilla with dist root in the right place
my $zilla2 = Dist::Zilla::Dist::Builder->from_config( { chrome => Dist::Zilla::Chrome::Test->new } );
$zilla2->release;

# check if dist.ini and changelog have been committed
my ($log) = $git->log( 'HEAD' );
like( $log->message, qr/v1.23\n[^a-z]*foo[^a-z]*bar[^a-z]*baz/, 'commit message taken from changelog' );

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
