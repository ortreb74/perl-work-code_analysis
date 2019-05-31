#!/usr/bin/env perl

use strict;
use warnings;

# in  : a three column analyzed table

# @indlede : liste des mots qui marquent l'ouverture d'un bloc
# @lukke : liste des mots qui marquent la fermeture d'un bloc

my %indlede = ( "{" => 1);
my %lukke = ( "}" => -1);

# $dybde : profondeur déduite des deux précédents

my $dybde = 0;


my $inputFileName = $1;
my $outputFileName = "$1.xml";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";

print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

my $code_line = "";
while ($code_line = <$inputFile>) {	
	## lecture de la table
	
	## calcul de la profondeur
	my $delta_dybde = 0;	

	my @words = split(" ",$code_line);	
	
	foreach my $word (@words) {
		if (exists ($rake{$word})) {
			# le mot est ignoré quand il fait partie
			# d'un mot clef rateau
			last;
		}
		
		if (exists ($indlede{$word})) {
			$dybde += 1;
			last;
		}
		
		if (exists ($lukke{$word})) {
			$delta_dybde -= 1;
			last;
		}			
	}		
	
	print $outputFile "<xsl:text>$dybde $code_line</xsl:text>;		
	
	$dybde += $delta_dybde;
}