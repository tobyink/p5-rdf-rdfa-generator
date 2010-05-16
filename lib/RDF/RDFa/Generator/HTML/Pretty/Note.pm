package RDF::RDFa::Generator::HTML::Pretty::Note;

use 5.008;
use common::sense;
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use XML::LibXML qw':all';

sub new
{
	my ($class, $subject, $text) = @_;
	
	return bless {
		'subject' => $subject,
		'text'    => $text,
		}, $class;
}

sub node
{
	my ($self, $namespace, $element) = @_;
	die "unknown namespace" unless $namespace eq XHTML_NS;
	
	my $node = XML::LibXML::Element->new($element);
	$node->setNamespace($namespace, undef, 1);
	
	$node->appendTextNode($self->{'text'});
	
	return $node;
}

sub is_relevant_to
{
	my ($self, $something) = @_;
	return $self->{'subject'}->equal($something);
}

*is_relevent_to = \&is_relevant_to;

1;