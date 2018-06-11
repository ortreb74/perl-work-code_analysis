#!/usr/local/bin/perl

# YE/MB 03/07/2014
##-------------------------------------------------------------------------------
#  03/07/2014 YE/MB : patch de la zapette des actuel TSA : modifier ../../Actuel/../... par ../../TSA/../..
#      on le fait ds un script pour simplifier la maintenance (d'autres modifs, ...)
##--------------------------------------------------------------------------------

my $motif = "TSA.xml\$";
my $fich = $ARGV[0];
print "fich = $fich\n";

open(F, "$fich") || die "Erreur : $fich pas ouvert! \n";
@tout = <F>;
$tout = $tout[0];
print "chargement fich Ok\n";
close(F);
print "$fich --> correction Zapette \"Actuel\" ==> \"TSA\" en cours...\n";
$tout =~ s/(<PAPI_meta name=\"classement\">ZAPETTE\/CATEGORIE)\/ActuEL\//$1\/TSA\//g;
$tout[0] = $tout;
print "Ok\n";
#-------------------------------------------------------------
#           REMISE EN ETATS DES MARQUEURS ET DU RETOUR CHARIOT
#-------------------------------------------------------------
print "Ok\n";

#-------------------------------------------------------------
#           ECRITURE DU RESULTAT
#-------------------------------------------------------------
$fich = "$fich".".out";
print "fichier resultat : $fich\n";
open(R, ">$fich");
print R @tout;
close(R);
print "Ok\n";



