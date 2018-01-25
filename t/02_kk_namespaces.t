#!/usr/bin/perl

# tests from KjetilK

use strict;
use Test::More;

use Attean;
use Attean::RDF qw(iri);



my $parser     = Attean->get_parser( 'turtle' )->new(base=>'http://example.org/');
my $iter = $parser->parse_iter_from_bytes( '</foo> a </Bar> .' );

my $store = Attean->get_store('Memory')->new();
$store->add_iter($iter->as_quads(iri('http://graph.invalid/')));
my $model = Attean::QuadModel->new( store => $store );

use RDF::RDFa::Generator;


subtest 'Default generator, old bugfix' => sub {
  ok(my $document = RDF::RDFa::Generator->new->create_document($model), 'Assignment OK');
  isa_ok($document, 'XML::LibXML::Document');
  my $string = $document->toString;
  
  unlike($string, qr|xmlns:http://www.w3.org/1999/02/22-rdf-syntax-ns#="rdf"|, 'RDF namespace shouldnt be reversed');
  like($string, qr|xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"|, 'Correct RDF namespace declaration');
};

subtest 'Default generator, single given NS' => sub {
  my $string = tests({ 'ex' => 'http://example.org/ns'}, 'xmlns:ex="http://example.org/ns"');
};

#subtest 'Default generator, single given NS' => sub {

#};


sub tests {
  my ($ns, $expect) = @_;
  ok(my $document = RDF::RDFa::Generator->new(namespaces => $ns)->create_document($model), 'Assignment OK');
  isa_ok($document, 'XML::LibXML::Document');
  my $string = $document->toString;
  like($string, qr|$expect|, 'Correct example namespace declaration');
  return $string;
}

done_testing();
