use lib "lib";

use RDF::TrineShortcuts;
use RDF::RDFa::Generator::HTML::Pretty;

my $graph = rdf_parse(<<TURTLE, type=>'turtle');

\@prefix foaf: <http://xmlns.com/foaf/0.1/> .
\@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://example.net/>

	a foaf:Document ;
	<http://www.w3.org/1999/xhtml/vocab#next> <http://example.net/page2> ;
	<http://www.w3.org/1999/xhtml/vocab#title> "About Joe"@en ;
	foaf:primaryTopic [
		a foaf:Person ;
		foaf:name "Joe Bloggs" ;
		foaf:plan "To conquer the world!"\@en
	] ;
	foaf:segment "Hello <b xmlns='http://www.w3.org/1999/xhtml'>World</b>"^^rdf:XMLLiteral .

TURTLE

my $gen = RDF::RDFa::Generator::HTML::Pretty->new(base=>'http://example.net/');

foreach my $n ($gen->nodes($graph))
{
	print $n->toString . "\n";
}
