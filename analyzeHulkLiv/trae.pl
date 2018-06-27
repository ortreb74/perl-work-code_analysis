#!/usr/bin/env perl

use strict;
use warnings;

# in  : a three column analyzed table

# @indlede : liste des mots qui marquent l'ouverture d'un bloc
# @lukke : liste des mots qui marquent la fermeture d'un bloc

my @indlede = ("pushd");
my @lukke = ("popd");

my %indleke_lukke = ( "pushd" => 1, "popd" => -1 ); 

# $dybde : profondeur déduite des deux précédents

my $dybde = 0;

# out : TBD ?

my $inputFileName = "out/analysis_table.txt";
my $outputFileName = "out/trae.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";

print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

my $line = "";
while ($line = <$inputFile>) {	

	my @columns = split("\t",$line);
	
	if ($#columns < 2) {
		print $line;
		continue;
	}
	
	my $lineNumber = $columns[0];
	my $type = $columns[1];	
	
	my $code_line = "";	
	
	# il faut reconstituer la ligne de code qui à l'origine pouvait comporter des \t	
	for (my $i = 2 ; $i < $#columns ; $i++) {						
		$code_line .= "\t" . $columns[$i];
	}
		
	$code_line .= $columns[$#columns];

	if ($type eq "code") {
		my @words = split(" ",$code_line);	
		
		foreach my $word (@words) {
			if (exists ($indleke_lukke{$word})) {
				$dybde += $indleke_lukke{$word};
			}
		}
		
	}
	
	print $outputFile $lineNumber . "\t" . $type . "\t" . $dybde . "\t" . $code_line;	
	
}