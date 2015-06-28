package Dist::Zilla::Role::Git::Repo;
# ABSTRACT: Provide repository information for Git plugins


use Moose::Role;
use MooseX::Types::Moose qw(Str Maybe);

has 'repo_root'   => ( is => 'ro', isa => Str, default => '.' );

=method current_git_branch

  $branch = $plugin->current_git_branch;

The current branch in the repository, or C<undef> if the repository
has a detached HEAD.  Note: This value is cached; it will not
be updated if the branch is changed during the run.

=cut

has current_git_branch => (
    is => 'ro',
    isa => Maybe[Str],
    lazy => 1,
    builder => '_build_current_git_branch',
    init_arg => undef,          # Not configurable
);

sub _build_current_git_branch
{
  my $self = shift;

  # Git 1.7+ allows "rev-parse --abbrev-ref HEAD", but we want to support 1.5.4
  my ($branch) = $self->git->RUN(qw(symbolic-ref -q HEAD));

  no warnings 'uninitialized';
  undef $branch unless $branch =~ s!^refs/heads/!!;

  $branch;
} # end _build_current_git_branch

=method git

  $git = $plugin->git;

This method returns a Git::Wrapper object for the C<repo_root>
directory, constructing one if necessary.  The object is shared
between all plugins that consume this role (if they have the same
C<repo_root>).

=cut

my %cached_wrapper;

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        # only report relative to dist root to avoid leaking private info
        repo_root => path($self->repo_root)->relative($self->zilla->root),
    };

    return $config;
};

sub git {
  my $root = shift->repo_root;

  $cached_wrapper{$root} ||= do {
    require Git::Wrapper;
    Git::Wrapper->new( $root );
  };
}

1;


__END__

=pod

=head1 DESCRIPTION

This role is used within the Git plugins to get information about the
repository structure, and to create a Git::Wrapper object.

=attr repo_root

The repository root, either as a full path or relative to the distribution root. Default is C<.>.
