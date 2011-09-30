use strict;
use warnings;

use inc::Module::Install;

my $dist = 'RDF-RDFa-Generator';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

test_requires       'Test::More' => '0.61';

requires            'common::sense'      => 0;
requires            'Data::Dumper'       => 0; # don't ask...
requires            'Icon::FamFamFam::Silk' => 0;
requires            'RDF::Trine'         => '0.112';
requires            'RDF::Prefixes'      => 0;
requires            'XML::LibXML'        => '1.60';

resources(
	'homepage'   => "https://metacpan.org/release/$dist",
	'repository' => "http://goddamn.co.uk/svn-web/perlmods/browse/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);

keywords 'RDF', 'RDFa', 'Semantic Web', 'Generator', 'Serializer', 'Serialiser', 'Output', 'Writer', 'HTML', 'XHTML';
	
write_doap_changes;
write_doap_changes_xml;
auto_license;
auto_manifest;

auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
