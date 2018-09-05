#!/usr/bin/env perl

use strict;
use warnings;

# in  : a code file
# out : an analysis of this code

# produced output : a tabulated table
# column 1 : # : line number of the source file
# column 2 : type of the column : comment / log (echo)  [ et on peut imaginer : code / internal function call / external function ]

# Règles de calcul de la colonne 2
# blank : /^\s*$/
# comment : /^\s*#/
# log : /^\s*echo/

# column 5 : value

my $program = "hulkliv";

my $inputFileName = "in/$program";
my $outputFileName = "out/analysis_table.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

# my %analyzedLine = {} ;
my $lineNumber = 1;
my $type = "";

my $line = "";

while ($line = <$inputFile>) {	
	$type = "code";
	
	if ($line =~ /^\s*$/) {
		$type = "blank";
	}	
	if ($line =~ /^\s*#/) {
		$type = "comment";
	} elsif ($line =~ /^\s*echo/) {
		$type = "log";
	}	
	
	print $outputFile $lineNumber . "\t" . $type . "\t" . $line;	
	$lineNumber++;
}

close ($inputFile);
close ($outputFile);