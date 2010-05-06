package RDF::RDFa::Generator::HTML::Pretty;

use 5.008;
use base qw'RDF::RDFa::Generator::HTML::Hidden';
use common::sense;
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use XML::LibXML qw':all';

sub nodes
{
	my ($proto, $model) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;
	
	my $stream = $self->_get_stream($model);
	my @nodes;
	
	my $root_node = XML::LibXML::Element->new('div');
	$root_node->setNamespace(XHTML_NS, undef, 1);
	
	my $prefixes = {};
	my $subjects = {};
	while (my $st = $stream->next)
	{
		my $s = $st->subject->is_resource ?
			$st->subject->uri :
			('_:'.$st->subject->blank_identifier);
		push @{ $subjects->{$s} }, $st;
	}
	
	foreach my $s (keys %$subjects)
	{
		my $subject_node = $root_node->addNewChild(XHTML_NS, 'div');
		
		$self->_process_subject($subjects->{$s}->[0], $subject_node, $prefixes);
		$self->_resource_heading($subjects->{$s}->[0]->subject, $subject_node, $subjects->{$s}, $prefixes);
		$self->_resource_classes($subjects->{$s}->[0]->subject, $subject_node, $subjects->{$s}, $prefixes);
		$self->_resource_statements($subjects->{$s}->[0]->subject, $subject_node, $subjects->{$s}, $prefixes);
		## TODO Query $model for statements that act as special notes for the subject (in a separate graph)
		#$self->_resource_notes($subjects->{$s}->[0]->subject, $subject_node, $model);
	}
	
	if ($self->{'version'} == 1.1
	and $self->{'prefix_attr'})
	{
		my $prefix_string = '';
		while (my ($u,$p) = each(%$prefixes))
		{
			$prefix_string .= sprintf("%s: %s ", $p, $u);
		}
		if (length $prefix_string)
		{
			$root_node->setAttribute('prefix', $prefix_string);
		}
	}
	else
	{
		while (my ($u,$p) = each(%$prefixes))
		{
			$root_node->setNamespace($u, $p, 0);
		}
	}
	
	push @nodes, $root_node;
	return @nodes if wantarray;
	my $nodelist = XML::LibXML::NodeList->new;
	$nodelist->push(@nodes);
	return $nodelist;
}

sub _resource_heading
{
	my ($self, $subject, $node, $statements, $prefixes) = @_;
	
	my $heading = $node->addNewChild(XHTML_NS, 'h3');
	$heading->appendTextNode( $subject->is_resource ? $subject->uri : ('_:'.$subject->blank_identifier) );
	$heading->setAttribute('class', $subject->is_resource ? 'resource' : 'blank' );
	
	return $self;
}

## TODO
## <span rel="rdf:type"><img about="[foaf:Person]" src="fsfwfwfr.png"
##                           title="http://xmlns.com/foaf/0.1/Person" /></span>

sub _resource_classes
{
	my ($self, $subject, $node, $statements, $prefixes) = @_;
	
	my @statements = sort {
		$a->predicate->uri cmp $b->predicate->uri
		or $a->object->uri cmp $b->object->uri
		}
		grep {
			$_->predicate->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
			and $_->object->is_resource
		}
		@$statements;

	return unless @statements;

	my $SPAN = $node->addNewChild(XHTML_NS, 'span');
	$SPAN->setAttribute('class', 'rdf-type');
	$SPAN->setAttribute('rel', $self->_make_curie('http://www.w3.org/1999/02/22-rdf-syntax-ns#type', $prefixes));

	foreach my $st (@statements)
	{
		my $IMG = $SPAN->addNewChild(XHTML_NS, 'img');
		$IMG->setAttribute('about', $st->object->uri);
		$IMG->setAttribute('alt',   $st->object->uri);
		$IMG->setAttribute('src',   $self->_img($st->object->uri));
		$IMG->setAttribute('title', $st->object->uri);
	}

	return $self;
}


sub _resource_statements
{
	my ($self, $subject, $node, $statements, $prefixes) = @_;
	
	my @statements = sort {
		$a->predicate->uri cmp $b->predicate->uri
		or $a->object->uri cmp $b->object->uri
		}
		grep {
			$_->predicate->uri ne 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
			or !$_->object->is_resource
		}
		@$statements;

	return unless @statements;
	
	my $DL = $node->addNewChild(XHTML_NS, 'dl');
	
	my $current_property = undef;
	foreach my $st (@statements)
	{
		unless ($st->predicate->uri eq $current_property)
		{
			my $DT = $DL->addNewChild(XHTML_NS, 'dt');
			$DT->setAttribute('title', $st->predicate->uri);
			$DT->appendTextNode($self->_make_curie($st->predicate->uri, $prefixes));
		}
		
		my $DD = $DL->addNewChild(XHTML_NS, 'dd');
		
		if ($st->object->is_resource)
		{
			$DD->setAttribute('rel',  $self->_make_curie($st->predicate->uri, $prefixes));
			$DD->setAttribute('class', 'resource');
			
			my $A = $DD->addNewChild(XHTML_NS, 'a');
			$A->setAttribute('href', $st->object->uri);
			$A->appendTextNode($st->object->uri);
		}
		elsif ($st->object->is_blank)
		{
			$DD->setAttribute('rel',  $self->_make_curie($st->predicate->uri, $prefixes));
			$DD->setAttribute('class', 'blank');
			
			my $A = $DD->addNewChild(XHTML_NS, 'span');
			$A->setAttribute('about', '_:'.$st->object->blank_identifier);
			$A->appendTextNode('_:'.$st->object->blank_identifier);
		}
		elsif ($st->object->is_literal
		&& !$st->object->has_datatype)
		{
			$DD->setAttribute('property',  $self->_make_curie($st->predicate->uri, $prefixes));
			$DD->setAttribute('class', 'plain-literal');
			$DD->setAttribute('xml:lang',  $st->object->literal_value_language);
			$DD->appendTextNode($st->object->literal_value);
		}
		elsif ($st->object->is_literal
		&& $st->object->has_datatype
		&& $st->object->literal_datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
		{
			$DD->setAttribute('property',  $self->_make_curie($st->predicate->uri, $prefixes));
			$DD->setAttribute('class', 'typed-literal datatype-xmlliteral');
			$DD->setAttribute('datatype',  $self->_make_curie($st->object->literal_datatype, $prefixes));
			$DD->appendWellBalancedChunk($st->object->literal_value);
		}
		elsif ($st->object->is_literal
		&& $st->object->has_datatype)
		{
			$DD->setAttribute('property',  $self->_make_curie($st->predicate->uri, $prefixes));
			$DD->setAttribute('class', 'typed-literal');
			$DD->setAttribute('datatype',  $self->_make_curie($st->object->literal_datatype, $prefixes));
			$DD->appendTextNode($st->object->literal_value);
		}
	}
	
	return $self;
}

sub _img
{
	my ($self, $type) = @_;
	
	my $icons = {
		'http://xmlns.com/foaf/0.1/Document' => 'data:image/png;charset=binary;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAz1JREFUWIXll0FPG0cUx38zuzgmllM7TQhRFFVVghGRkIBYqJz6HfoFyIEb36HXHnPiGIlP0I/QWy6oQkKqBAdXTghxD03BwnaK1zs7OeBZz65n2TVKT32StTPjnfd+83/PM2P4v5tID+zt7f3k+/4+UPU8DyklURShlIo/YRjGT7t90xjQC8Pw1f7+/q92PH+KSIg3Ozs71XGbMAzxfR+tdeI9u1+wXd3d3X0D3AyglKoBtNtthBAopahUKgRBYAARYiKc3Xb1DcjCwgJBENTS300BaK3jIMZZuu16ZgXPsymAKIoSQe1ArVYr/r5IUM/zaDQaicUVAjAqpEGWlpb+ewWUUgmHtgp5Cniex/Lycmawwgq4ggshaDQat1LAjBcCMAq4ivDo6KhQINs2Njbi9kwAAIeHh6yvr0/UkB4d+YQfGn9Tr97l7Ymm2687YQCe6nYCygUgXQCmCDc3N+NJxlHlzr98t9CgXnnB0uLnKYejwTk6CuO+rWRhADMxiqKpHA+CMp/67/kcvOPsn3JychQyPD+l9+73RA0ZH+kChpwUuFYRRSV+O6rhyZBgdB8hJ4C9sz8Qns/w4iNajUCSmwIngL0bpgEe3JUI4QElRHnifNjvct79QP3xM3S1zqNv5qGXBCikwPjkcprWms6f7RjKtuCqiyg9oPvpAi3nOWu1eL4oZgdI/wzTeexedjMOIIHSZa4GXaTnc9lv83zx+0QB3roGLAkY9C9v3ny8EqMwREeThZjcFwbIPhHhx5dPM4O7NqKZi9CugYODA5rNZtxvNpvO1LhgswLmAtgp2NraYjgcxk5PTk4SNeJ6Jpz7Pqurq7MDGHKlVGJlKysruQrk7XyFAIylV3V8fJx5WLnm3EoBUwMuSY0CUspCKmitc1W4MQVpMwpk5d/3fdbW1ma6GWWmwL6WGbNrIEuF9LU8T4WZtmLb0sd0eryopQGqUspLrfW9Wu36Cq+UYm5ubmbHxmzAUqnUAxaBC2CYBqgCDzudzi/b29s/A/O3ipgNcnV6evoaeAx4wF9AZOtXAh4B3wI14M74xa9hV1wvdgCcAx+APjj+nI4Dl8dAs1/03RYBI65lHwJxPr8AVhTGqEDsvuoAAAAASUVORK5CYII=' ,
		'http://xmlns.com/foaf/0.1/Person'   => 'data:image/png;charset=binary;base64,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',
		'http://xmlns.com/foaf/0.1/Group'    => 'data:image/png;charset=binary;base64,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',
		'http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing' => 'data:image/png;charset=binary;base64,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' ,
		'?'                                  => 'data:image/png;charset=binary;base64,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',
	};
	
	my $equiv = {
		'http://xmlns.com/foaf/0.1/PersonalProfileDocument'  => 'http://xmlns.com/foaf/0.1/Document' ,
		'http://www.w3.org/2003/01/geo/wgs84_pos#Point'      => 'http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing' , 
		'http://www.w3.org/2006/vcard/ns#Location'           => 'http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing' , 
	};
	
	return $icons->{$type} || $icons->{ $equiv->{$type} } || $icons->{'?'};
}

1;
