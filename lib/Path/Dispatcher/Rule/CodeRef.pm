package Path::Dispatcher::Rule::CodeRef;
use Any::Moose;
extends 'Path::Dispatcher::Rule';

has matcher => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

sub _match {
    my $self = shift;
    my $path = shift;

    local $_ = $path;
    return $self->matcher->($path);
}

sub readable_attributes {
    return if $ENV{'PATH_DISPATCHER_TRACE'} < 10;

    my $self = shift;

    require B::Deparse;
    return B::Deparse->new->coderef2text($self->matcher);
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::CodeRef - predicate is any subroutine

=head1 SYNOPSIS

    my $rule = Path::Dispatcher::Rule::CodeRef->new(
        matcher => sub { time % 2 },
        block => sub { warn "Odd time!" },
    );

    my $undef = $rule->match("foo"); # even time; no match :)

    my $match = $rule->match("foo"); # odd time; creates a Path::Dispatcher::Match

    $rule->run; # warns "Odd time!"

=head1 DESCRIPTION

Rules of this class can match arbitrarily complex values. This should be used
only when there is no other recourse, because there's no way we can inspect
how things match. Create a custom subclass of L<Path::Dispatcher::Rule> if
necessary!

=head1 ATTRIBUTES

=head2 matcher

A coderef that returns C<undef> if there's no match, otherwise a list of
strings (the results).

The coderef receives the path object as its argument, and the path string as
C<$_>.

=cut

