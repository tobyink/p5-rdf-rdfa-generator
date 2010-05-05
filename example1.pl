use lib "lib";

use RDF::TrineShortcuts;
use RDF::RDFa::Generator::HTML::Hidden;

my $graph = rdf_parse(<<TURTLE, type=>'turtle');

\@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.net/>

	a foaf:Document ;
	<http://www.w3.org/1999/xhtml/vocab#next> <http://example.net/page2> ;
	<http://www.w3.org/1999/xhtml/vocab#title> "About Joe"@en ;
	foaf:primaryTopic [
		a foaf:Person ;
		foaf:name "Joe Bloggs" ;
		foaf:plan "To conquer the world!"\@en
	] .

TURTLE

my $gen = RDF::RDFa::Generator::HTML::Hidden->new(base=>'http://example.net/');

foreach my $n ($gen->nodes($graph))
{
	print $n->toString . "\n";
}