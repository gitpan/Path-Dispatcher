#!/usr/bin/env perl
package Path::Dispatcher::Match;
use Moose;

use Path::Dispatcher::Rule;

has path => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has leftover => (
    is  => 'rw',
    isa => 'Str',
);

has rule => (
    is       => 'rw',
    isa      => 'Path::Dispatcher::Rule',
    required => 1,
);

has result => (
    is => 'rw',
);

has set_number_vars => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { ref(shift->result) eq 'ARRAY' },
);

sub run {
    my $self = shift;
    my @args = @_;

    local $_ = $self->path;

    if ($self->set_number_vars) {
        $self->run_with_number_vars(
            sub { $self->rule->run(@args) },
            @{ $self->result },
        );
    }
    else {
        $self->rule->run(@args);
    }
}

sub run_with_number_vars {
    my $self = shift;
    my $code = shift;

    # we don't have direct write access to $1 and friends, so we have to
    # do this little hack. the only way we can update $1 is by matching
    # against a regex (5.10 fixes that)..
    my $re = join '', map { "(\Q$_\E)" } @_;
    my $str = join '', @_;

    # we need to check length because Perl's annoying gotcha of the empty regex
    # actually being an alias for whatever the previously used regex was 
    # (useful last decade when qr// hadn't been invented)
    # we need to do the match anyway, because we have to clear the number vars
    ($str, $re) = ("x", "x") if length($str) == 0;
    $str =~ $re
        or die "Unable to match '$str' against a copy of itself!";

    $code->();
}

# If we're a before/after (qualified) rule, then yeah, we want to continue
# dispatching. If we're an "on" (unqualified) rule, then no, you only get one.
sub ends_dispatch {
    my $self = shift;

    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Match - the result of a successful rule match

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::Tokens->new(
        tokens => [ 'attack', qr/^\w+$/ ],
        block  => sub { attack($2) },
    );

    my $match = $rule->match("attack dragon");

    $match->path            # "attack dragon"
    $match->leftover        # empty string (populated with prefix rules)
    $match->rule            # $rule
    $match->result          # ["attack", "dragon"] (decided by the rule)
    $match->set_number_vars # 1 (boolean indicating whether to set $1, $2, etc)

    $match->run                         # causes the player to attack the dragon
    $match->run_with_number_vars($code) # runs $code with $1=attack $2=dragon

=head1 DESCRIPTION

If a L<Path::Dispatcher::Rule> successfully matches a path, it creates one or
more C<Path::Dispatcher::Match> objects.

=head1 ATTRIBUTES

=head2 rule

The L<Path::Dispatcher::Rule> that created this match.

=head2 path

The path that the rule matched.

=head2 leftover

The rest of the path. This is populated when the rule matches a prefix of the
path.

=head2 result

Arbitrary results generated by the rule. For example, L<Path::Dispatcher::Rule::Regex> rules' result is an array reference of capture variables.

=head2 set_number_vars

A boolean indicating whether invoking the rule should populate the number variables (C<$1>, C<$2>, etc) with the array reference of results.

Default is true if the C<result> is an array reference; otherwise false.

=head1 METHODS

=head2 run

Executes the rule's codeblock with the same arguments. If L</set_number_vars>
is true, then L</run_with_number_vars> is used, otherwise the rule's codeblock
is invoked directly.

=head2 run_with_number_vars coderef, $1, $2, ...

Populates the number variables C<$1>, C<$2>, ... then executes the coderef.

Unfortunately, the only way to achieve this (pre-5.10 anyway) is to match a
regular expression. Both a string and a regex are constructed such that
matching will produce the correct capture variables.

=cut

