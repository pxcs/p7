# RDF::Query::CostModel::Logged
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Query::CostModel::Logged - Execution cost estimator

=head1 METHODS

=over 4

=cut

package RDF::Query::CostModel::Logged;

our ($VERSION);
BEGIN {
	$VERSION	= '2.002';
}

use strict;
use warnings;
no warnings 'redefine';
use base qw(RDF::Query::CostModel);

use RDF::Query::CostModel::Naive;

use Set::Scalar;
use Data::Dumper;
use Scalar::Util qw(blessed refaddr);
use List::MoreUtils qw(uniq);

=item C<< new ( $logger ) >>

Return a new cost model object.

=cut

sub new {
	my $class	= shift;
	my $logger	= shift;
	my $self	= $class->SUPER::new( @_ );
	$self->{l}	= $logger;
	$self->{n}	= RDF::Query::CostModel::Naive->new();	# a naive costmodel to fall back on when no logging data is available
	return $self;
}

=item C<< logger >>

Returns the RDF::Query::Logger object this cost model is based on.

=cut

sub logger {
	my $self	= shift;
	return $self->{l};
}

sub _cost_nestedloop {
	my $self	= shift;
	my $bgp		= shift;
	my $context	= shift;
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	$l->debug( 'Computing COST: ' . $bgp->sse( {}, '' ) );
	return $self->_cardinality( $bgp, $context );
}

sub _cost_triple {
	my $self	= shift;
	my $triple	= shift;
	my $context	= shift;
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	$l->debug( 'Computing COST: ' . $triple->sse( {}, '' ) );
	return $self->_cardinality( $triple, $context );
}

################################################################################

sub _cardinality_triple {
	my $self	= shift;
	my $pattern	= shift;
	my $context	= shift;
	my $size	= $self->_size;
	my $bf		= $pattern->bf;
	my $f		= ($bf =~ tr/f//);
	my $r		= $f / 3;
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	
	my $logger		= $self->logger;
	my ($card, $sd)	= $logger->get_statistics( 'cardinality-bf-triple', $bf );
	if ($card) {
		$l->debug( "Expected cardinality of $bf TRIPLE is : " . $card . " (with stddev of $sd)" );
		return $card;
	} else {
		$l->debug('falling back on naive costmodel');
		return $self->{n}->_cardinality_triple( $pattern, $context );
	}
}

sub _cardinality_service {
	my $self	= shift;
	my $pattern	= shift;
	my $context	= shift;
	die;
}

sub _cardinality_nestedloop {
	my $self	= shift;
	my $pattern	= shift;
	my $context	= shift;
	my @triples	= ($pattern->lhs, $pattern->rhs);
	my $size	= $self->_size;
	my $bf		= $pattern->bf;
	my @bf		= split(/,/, $bf);
	my $l		= Log::Log4perl->get_logger("rdf.query.costmodel");
	
	$l->debug( "looking for cardinality-bf-nestedloop -> $bf" );
	my $logger		= $self->logger;
	my ($card, $sd)	= $logger->get_statistics( 'cardinality-bf-nestedloop', $bf );
	if ($card) {
		$l->debug( "Expected cardinality of $bf BGP is : " . $card . " (with stddev of $sd)" );
		return $card;
	} else {
		$l->debug('falling back on naive costmodel');
		return $self->{n}->_cardinality_nestedloop( $pattern, $context );
	}
}



1;

__END__

=back

=head1 AUTHOR

 Gregory Todd Williams <gwilliams@cpan.org>

=cut
