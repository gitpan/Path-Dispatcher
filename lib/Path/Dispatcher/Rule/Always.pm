package Path::Dispatcher::Rule::Always;
use Moose;
extends 'Path::Dispatcher::Rule';

sub _match {
    my $self = shift;
    my $path = shift;
    return (1, $path->path);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

Path::Dispatcher::Rule::Always - always matches

=head1 DESCRIPTION

Rules of this class always match. If a prefix match is requested, the full path
is returned as leftover.

=cut

