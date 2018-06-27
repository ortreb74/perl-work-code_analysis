#!/usr/bin/env perl

use strict;
use warnings;

# in  : a four column analyzed table

# column 1 : # : line number of the source file
# column 2 : type of the column : comment / log (echo)  [ et on peut imaginer : code / internal function call / external function ]
# column 3 : profondeur de bloc
# column 4 : value

# out : a directory which contains a file for each bloc
# [a bloc is a new zero]

# IO definition 

my $inputFileName = "out/trae.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";

my $outputDirectory = "out/bloc";

system("mkdir $outputDirectory 2>/dev/null");
# -f $outputDirectory or die "impossible de créer le répertoire $outputDirectory";

my $blocnumber = 1;
my $outputFileName = $outputDirectory . "/" . "bloc-" . $blocnumber . ".txt";

print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

my $root = 1;

# Read the input
my $line = "";
while ($line = <$inputFile>) {	

	my @columns = split("\t",$line);
	
	if ($#columns < 3) {
		print $line;
		continue;
	}
	
	my $lineNumber = $columns[0];
	my $type = $columns[1];	
	my $depth = $columns[2];	
	
	my $code_line = "";	
	
	# il faut reconstituer la ligne de code qui à l'origine pouvait comporter des \t	
	for (my $i = 3 ; $i < $#columns ; $i++) {						
		$code_line .= "\t" . $columns[$i];
	}
	
	$code_line .= $columns[$#columns];
	
	if ($depth > 0 && $root == 1) {
		close($outputFile);
		$blocnumber++;
		$outputFileName = $outputDirectory . "/" . "bloc-" . $blocnumber . ".txt";

		print "Ecriture du fichier : $outputFileName\n";
		open ($outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";		
	}
	
	$root = ($depth == 0) ? 1 : 0;	
	
	print $outputFile $lineNumber . "\t" . $type . "\t" . $depth . "\t" . $code_line;	
}

