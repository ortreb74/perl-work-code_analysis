#!/usr/local/bin/perl -w
# --------------------------------------------------------
# Auteur : Ahmed LAZREG
# Date   : 14/01/2013
# --------------------------------------------------------
# Rappels généraux perl :

# sub myfunction{...} => déclaration d'une fonction

# &myfunction(arg1,arg2,...); => appel à la fonction avec des arguments

# myfunction arg1; => appel à la fonction sans le caractère & ni parenthèses

# compraison de chaines avec l'opérateur 'eq' et pas '=='

# Lire les paramètre d'une fonction
# Solution 1
# my(@args) = @_; => dans une fonction permet de récupérer les paramètres de la fonction dans un tableau local @args
# my $variable = $args[0]; dans une fonction permet de récupérer l'argument 0
# my $variable = $args[x]; dans une fonction permet de récupérer l'argument x

# Solution 2
# $_[0] => dans une fonction permet de récupérer l'argument 0
# $_[1] => dans une fonction permet de récupérer l'argument 1
# $_[x] => dans une fonction permet de récupérer l'argument x
# --------------------------------------------------------
#
# dico elnet/hulk à alimenter
# ajouter le lp35 + sources

# dp01 dp02 dp03 dp04 dp05 dp06 dp09 dp10 dp11 dp12 dp13 dp14 dp15 dp16 dp17 dp18 dp21 dp22 dp26 dp34 dp36 gp20 gp23 gp25 gp59 gp66 gp67 gp68 gp74 lp35 sources
# --------------------------------------------------------

# --------------------------------------------------------
# Inclusion des modules perl
# --------------------------------------------------------
##use strict;
use warnings;
use POSIX qw/strftime/; ## pour la manipulation des objets time
use Switch;


# --------------------------------------------------------
## Inclusion de librairies personnelles perl
# --------------------------------------------------------
require("/usr/local/ela/bin/alimhulk.lib.pl");

## 26/12/2013 MB : ajout 2 codes EL : cic et cdpcc (a modifier aussi dans hulk.bal et hulk_test.bal)
##my @listeCodesEL = ("ccva","cdc","cm","cmp","cpca","cra","ctm","cua","cpmiv");
my @listeCodesEL = ("ccva","cdc","cm","cmp","cpca","cra","ctm","cua","cpmiv","cic","cdpcc");

# --------------------------------------------------------
# Déclaration des variables globales
# --------------------------------------------------------
$g_exitval = 18;

##my $dico = $ARGV[0];

$dico = "";
$g_mode = "na";
$ela_cdrom = "/usr/local/ela/cd-rom";
$hulk_liv = "$ela_cdrom/hulk/liv";
##$hulk_liv_alimhulk = "$hulk_liv/alimhulk";
$hulk_liv_alimhulk = "";

$dpxx_liv = "";
$dpxx_liv_archive_lastfullmaj = "";

# --------------------------------------------------------
# Déclaration des fonctions
# --------------------------------------------------------
sub afficher_syntaxe{
	&printn("");

	&printn("La commande 'alimhulk.pl dico' permet d'alimenter les données validées de dpxx/liv/archive/lastfullmaj/*/ vers le dossier hulk/liv/alimhulk/dpxx/");
	&printn("");

	&printn("Syntaxe :");
	&printn("alimhulk.pl dico [test]");
	&printn("dico = dpxx gpxx lpxx (ex : dp01 gp25 lp35 elnet ou sources)");
	&printn("elnet ou sources = permet de récupérer les données depuis ELA_DATA de elnet (elnet/data/sgml/)");
	&printn("bofip = permet de récupérer les données Bofip sans les autres sources depuis ELA_DATA de elnet (elnet/data/sgml/)");
	&printn("codes = permet de récupérer les données codes EL sans les autres sources depuis ELA_DATA de elnet (elnet/data/sgml/)");
	&printn("test = préciser cet argument pour alimenter le dossier hulk/livtest/alimhulk/");

	&printn("");

	return 0;
}

sub parser_les_arguments_du_programme{
	## Cette fonction parse les arguments et positionne les variables globales
	&printn("parcours des arguments du programme");
	##printn("parcours des arguments du programme 2");

	## ---------------------------------------------------------------------------------
	## ATTENTION AU COMPTAGE DES ARGUMENTS DU PROGRAMME
	## $#ARGV retourne l'index du dernier element, soit le nombre d'argument - 1
	## Exemple avec prog.pl dpxx => on obtient 0 (l'index du dernier argument) et non 1

	## Il faut utiliser une des notations suivantes pour obtenir la taille d'un tableau
	## 1. my $size = $#array+1;
	## $#array retourne l'index du dernier element de @array,
	## et comme l'index commence à 0 il suffit d'ajouter 1 pour avoir la taille...
	## 
	## 2. my $size = scalar(@ARGV)
	## 
	## ---------------------------------------------------------------------------------
	## &printn("nombre d'arguments = $#ARGV");
	## &printn("nombre d'arguments = scalar($#ARGV)");
	## &printn("nombre d'arguments = ".scalar(@ARGV));
	## &printn("nombre d'arguments = @ARGV");
	## ---------------------------------------------------------------------------------
	my $nbArgsDuProgramme = $#ARGV+1;
##    my $nbArgsDuProgramme = scalar(@ARGV);
	## ---------------------------------------------------------------------------------

	
	if ( $nbArgsDuProgramme < 1 ){
	&printn("Vous devez fournir au moins un argument => le dico");
	&afficher_syntaxe();
	return 1;
	}

	## Tester si le dico existe
	my $ela_cdrom_dico = $ela_cdrom.'/'.$ARGV[0];
	$dico = $ARGV[0];

	if ( $nbArgsDuProgramme >= 2 ){
	if ($ARGV[1] eq "sandbox1" || $ARGV[1] eq "-sandbox1" || $ARGV[1] eq "sbox1") {$g_mode = "sandbox1";}
	if ($ARGV[1] eq "sandbox4" || $ARGV[1] eq "-sandbox4" || $ARGV[1] eq "sbox4") {$g_mode = "sandbox4";}
	if ($ARGV[1] eq "test" || $ARGV[1] eq "-test") {$g_mode = "test";}
	if ($ARGV[1] eq "prod" || $ARGV[1] eq "-prod") {$g_mode = "prod";}
	}

##    for($i=0;$i<=$#ARGV;$i++){
##	##printn $ARGV[$i];
##	if ($ARGV[$i] eq "test" || $ARGV[$i] eq "-test"){
##	    $g_mode = "test";
##	}
##	elsif ($ARGV[$i] eq "prod" || $ARGV[$i] eq "-prod"){
##	    $g_mode = "prod";
##	}
##    }


	$hulk_liv = "$ela_cdrom/hulk/liv";
	if ($g_mode eq "test"){$hulk_liv = "$ela_cdrom/hulk/livtest";}
	if ($g_mode eq "sandbox1"){$hulk_liv = "$ela_cdrom/hulk/sandbox1";}
	if ($g_mode eq "sandbox4"){$hulk_liv = "$ela_cdrom/hulk/sandbox4";}
	$hulk_liv_alimhulk = "$hulk_liv/alimhulk";

	&printn("mode = '$g_mode'");
	&printn("dico = '$dico'");

	return 0;
}

sub abandonner{
	my(@args) = @_;

	## Fermer les filestream qui sont ouverts puis quitter le programme

	exit $args[0];
}

sub alimhulk_dp29{
	# my $dico = "dp29";
	my $dossierSource = $ela_cdrom.'/dp29/liv/archive/lastfullmaj';
	my $dossierCible = $hulk_liv_alimhulk.'/dp14';
	my $commande = "cp $dossierSource/sgm/dp14_tag?.*.sgm $dossierCible/sgm";
	system($commande);
	my $commande = "cp $dossierSource/sgm/dp14_lst-et?.*.sgm $dossierCible/sgm";
	system($commande);
	my $commande = "cp $dossierSource/sgm/dp14_lst-code2.*.sgm $dossierCible/sgm";
	system($commande);
}

sub alimhulk_dp33{
	# my $dico = "dp29";
	my $dossierSource = $ela_cdrom.'/dp33/liv/archive/lastfullmaj';
	my $dossierCible = $hulk_liv_alimhulk.'/dp33';
	system("mkdir -p ".$dossierCible.'/sgm');
	my $commande = "cp $dossierSource/sgm/c*w3*.sgm $dossierCible/sgm";
	system($commande);
}

## pour la majorité des dico récupérer le contenu de lastfullmaj
sub alimhulk_dpxx_gpxx{
	&printn("je suis dans la fonction alimhulk_dpxx_gpxx");
	my(@args) = @_;
	my $dico = $args[0];

	## pour la majorité des dico récupérer le contenu de lastfullmaj

	my $dossierSource = $dpxx_liv_archive_lastfullmaj;

	## cas particuliers
	if ($dico eq "gp69") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp74") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp76") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp95") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp114") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp166") {$dossierSource = $dpxx_liv;}
	if ($dico eq "gp259") {$dossierSource = $dpxx_liv;}

	my $dossierCible = $hulk_liv_alimhulk.'/'.$dico;

## pas besoin de copier le dossier dpxx/liv/dtd/ car on récupérera celui de elnet ou ELA_DTD

	copierDossierVersDossier($dossierSource.'/prodmaps','',$dossierCible);

	## 24/09/2013 MB : suite pb melange anciens et nouveaux formats des fp/qr/mt du gp23 dans Hulk prod du 23/09/2013
	##                ==> on nettoie systematiquement le dossier avant realimentation
	supprimerFichersDuDossier($dossierCible.'/sgm','*.sgm');
	copierDossierVersDossier($dossierSource.'/sgm','',$dossierCible);

	## supprimer les jrpbloc + txtbloc + tap
	## les jrpbloc seront recontruits par le script hulkliv.pl pour toutes les matières
	## les txtbloc des sources seront livrés. Ils couvrent l'ensemble des matières
	## les fichiers tap ne sont pas livrées sur la pate forme hulk. Les TAP sont présente dans les fichiers *body.sgm
	supprimerFichersDuDossier($dossierCible.'/sgm','*_jrpbloc*.sgm');
	supprimerFichersDuDossier($dossierCible.'/sgm','*_txtbloc*.sgm');
	supprimerFichersDuDossier($dossierCible.'/sgm','*.tap.sgm');
	## suite pb fichier subscription manquant au hulkliv -mat dp17
	## vu avec Armand jouve, ce fichier n'est pas utilise dans Hulk mais son absence fait planter la chaine jouve.
	## ==> on alimente par defaut (en attendant de l'ignorer dans la chaine jouve)
	## supprimerFichersDuDossier($dossierCible.'/sgm','subscription.sgm');
	supprimerFichersDuDossier($dossierCible.'/sgm','*.lref.sgm');

	# 05/05/2017 ALAZREG GP259 on ne retrouve pas le fichier ./gp259/liv/sgm/a9cl0023.optj.sgm dans le dossier hulk/alimhulk/gp259/sgm
	# c'est certainement à cause de la regexp dessous. Je desactive la regexp pour tester
	supprimerFichersDuDossier($dossierCible.'/sgm','[0-9]*.sgm');

	supprimerFichersDuDossier($dossierCible.'/sgm','tcb.sgm');
	supprimerFichersDuDossier($dossierCible.'/sgm','external.sgm');

	supprimerLesCodesDuDossier($dossierCible.'/sgm');

	## cas dp15
	## renommer le comjrp en dp15_comjrp comme elnet
	## cela facilite les commandes
	if ($dico eq "dp15"){
		my $dossier = $hulk_liv_alimhulk.'/'.$dico.'/sgm';
		foreach my $fichier ('comjrp.optj.sgm','comjrp.toc.sgm') {
			if (-f $dossier.'/'.$fichier){
				my $commande = "mv $dossier/$fichier $dossier/".$dico."_".$fichier;
				##printn($commande);
				system($commande);
			}
		}
	}

	copierDossierVersDossier($dossierSource.'/www','',$dossierCible);
	copierFichersVersDossier($dossierSource,'cdcoll.sgm.txt',$dossierCible);
	copierFichersVersDossier($dossierSource.'/xml/','*.xml',$dossierCible.'/xml');
	
	if ($dico eq "dp14"){
		&alimhulk_dp29;
	}
}

## pour le lp35 => cas particulier
sub alimhulk_lp35{
	&printn("je suis dans la fonction alimhulk_lp35");
	## récupérer seulement les formules interactives
	my $dossierCible = $hulk_liv_alimhulk.'/'.$dico;

	copierFichersVersDossier($dpxx_liv.'/xml/','*.xml',$dossierCible.'/xml');
	copierDossierVersDossier($dpxx_liv.'/sgm/','',$dossierCible);
}

## pour les sources => cas particulier
sub alimhulk_sources{
	&printn("je suis dans la fonction alimhulk_sources");

	my $dossierCible = $hulk_liv_alimhulk.'/sources';

	# 05/09/2017 alzreg https://jira.els-gestion.eu/browse/SIECDP-265
	# on ne copie pas les txtbloc car ils seront reconstruits dans le dossier hulk/liv/sgm
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocs/uaur','*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocs/toc/uaur','*.toc.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocsANT/uaur','*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocsANT/toc/uaur','*.toc.sgm',$dossierCible.'/sgm');

	# on ne copie pas les jrpbloc car ils seront reconstruits dans le dossier hulk/liv/sgm

	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/docam/uaur','*.optj.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/docam/toc/uaur','*.toc.sgm',$dossierCible.'/sgm');

	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/bofip/uaur','bofip*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/bofip/toc/uaur','bofip*.toc.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/datacomm/bofip/uaur','bofip*.optj.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/datacomm/bofip/toc/uaur','bofip*.toc.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/listels/uaur','elnet_lst-bofip.optj.sgm',$dossierCible.'/sgm');

	## copierDossierVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','',$dossierCible);

	## 27/05/2013 AL/MB : les codes ne sont plus alimentes par le script hulkliv ==> on le fait ici
	foreach my $unCode (@listeCodesEL) {
		copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/code/uaur',"$unCode".".optj.sgm",$dossierCible.'/sgm');
		copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/code/toc/uaur',"$unCode".".toc.sgm",$dossierCible.'/sgm');
	}
}


## 27/05/2013 AL/MB : ajout fonction : alimhulk_txt pour possibilite d'alimenter txt seul (sans les codes/jrp/bofip)
sub alimhulk_txt{
	&printn("je suis dans la fonction alimhulk_txt dossier cible = $hulk_liv_alimhulk/sources/sgm");
	my $dossierCible = $hulk_liv_alimhulk.'/sources';

	## on nettoie le dossier cible pour Bofip (qui est le même que pour les sources
	print "******* Nettoyage du dossier : $dossierCible/sgm/* avant livraison des txt\n";
	supprimerFichersDuDossier($dossierCible.'/sgm','*');

	# 05/09/2017 alzreg https://jira.els-gestion.eu/browse/SIECDP-265
	# on ne copie pas les txtbloc car ils seront reconstruits dans le dossier hulk/liv/sgm
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocs/uaur','*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocs/toc/uaur','*.toc.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocsANT/uaur','*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/txtblocsANT/toc/uaur','*.toc.sgm',$dossierCible.'/sgm');

	## 27/05/20213 AL/MB : pour les codes, pas besoin des maps
	## copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','codedata.map',$dossierCible.'/prodmaps');
	## copierDossierVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','',$dossierCible);
}



## 26/04/2013 MB : ajout fonction : alimhulk_bofip pour possibilite d'alimenter Bofip seul (sans les txt/jrp)
## pour les sources => cas particulier
sub alimhulk_bofip{
	&printn("je suis dans la fonction alimhulk_bofip dossier cible = $hulk_liv_alimhulk/sources/sgm");
	my $dossierCible = $hulk_liv_alimhulk.'/sources';

	## on nettoie le dossier cible pour Bofip (qui est le même que pour les sources
	print "******* Nettoyage du dossier : $dossierCible/sgm/* avant livraison les docs Bofip\n";
	supprimerFichersDuDossier($dossierCible.'/sgm','*');

	## 26/04/2013 MB : les docs Bofip sont a prendre de /usr/local/ela/cd-rom/elnet/data/sgml/bofip/uaur
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/bofip/uaur','bofip*.optj.sgm',$dossierCible.'/sgm');
	# copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/bofip/toc/uaur','bofip*.toc.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/datacomm/bofip/uaur','bofip*.optj.sgm',$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/datacomm/bofip/toc/uaur','bofip*.toc.sgm',$dossierCible.'/sgm');

	## 26/04/2013 MB : on ajoute la liste Bofip
	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/listels/uaur','elnet_lst-bofip.optj.sgm',$dossierCible.'/sgm');
	## MB: inutile, desactiver
	##copierDossierVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','',$dossierCible);

}


## 27/05/2013 AL/MB : ajout fonction : alimhulk_codes pour possibilite d'alimenter codes EL seul (sans les txt/jrp/bofip)
sub alimhulk_codes{
	&printn("je suis dans la fonction alimhulk_codes dossier cible = $hulk_liv_alimhulk/sources/sgm");
	my $dossierCible = $hulk_liv_alimhulk.'/sources';

	## on nettoie le dossier cible pour Bofip (qui est le même que pour les sources
	print "******* Nettoyage du dossier : $dossierCible/sgm/* avant livraison des codes EL\n";
	supprimerFichersDuDossier($dossierCible.'/sgm','*');

	foreach my $unCode (@listeCodesEL) {
	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/code/uaur',"$unCode".".optj.sgm",$dossierCible.'/sgm');
	copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/code/toc/uaur',"$unCode".".toc.sgm",$dossierCible.'/sgm');
	}

	## 27/05/20213 AL/MB : pour les codes, pas besoin des maps
	## copierFichersVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','codedata.map',$dossierCible.'/prodmaps');
	## copierDossierVersDossier('/usr/local/ela/cd-rom/elnet/data/sgml/prodmaps','',$dossierCible);
}



sub poser_la_date_de_copie_alimhulk{
	&printn("je suis dans la fonction poser_la_date_de_copie_alimhulk");
	my(@args) = @_;
	my $aa_mm_jj = &get_date_aaaa_mm_jj();
	my $hh_mm_ss = &get_heure_hh_mm_ss();
	my $dossier = $args[0];

##    open(FILE_DATE_DER_PROD,">$hulk_liv_alimhulk/$dico/date_derniere_copie_alimhulk.txt");
	open(FILE_DATE_DER_PROD,">$dossier/date_derniere_copie_alimhulk.txt");
	printf FILE_DATE_DER_PROD "Copie réalisée le $aa_mm_jj à $hh_mm_ss\n";
	printf FILE_DATE_DER_PROD "Par $ENV{'USER'}\n";
	printf FILE_DATE_DER_PROD "Commande : alimhulk.pl @ARGV\n";
	close(FILE_DATE_DER_PROD);

##    printn("ENV user = ".$ENV{'USER'});
}

##&func_test(1,2,3);

sub main(){
## si le parse des arguments du programme échoue ce n'est pas la peine d'aller plus loin
my $retour = &parser_les_arguments_du_programme();
if ($retour != 0) {
	&printn("La fonction parser_les_arguments_du_programme a retourné un code différent de zéro ($retour)");
	&printn("abandon du programme");
	abandonner($retour);
}
else{ ## traitement du dico parametre

	$dpxx_liv = $ela_cdrom."/".$dico."/liv";
	$dpxx_liv_archive_lastfullmaj = $dpxx_liv."/archive/lastfullmaj";

	## pour le lp35 => cas particulier
##    if($dico eq 'lp35') {&alimhulk_lp35($dico);}
	## pour les sources => cas particulier
	## ne pas récupérer la jrp car elle sera recontruite par le script hulkliv
	## récupérer les sources txt docam depuis ela_data
##    elsif ($dico eq 'sources' || $dico eq 'elnet') {&alimhulk_sources($dico);}
	## pour la majorité des dico récupérer le contenu de lastfullmaj
##    else {&alimhulk_dpxx_gpxx($dico);}
	
	##   use Switch;
	## Source : http://perldoc.perl.org/Switch.html
	switch ($dico) {
		case "dp33" {&alimhulk_dp33($dico);}
		case "lp35" {&alimhulk_lp35($dico);}
		case "sources" {&alimhulk_sources($dico);}
		## 27/05/2013 AL/MB : ajout option txt pour alimenter uniquement avec les txt (sans les autres sources)
		case "txt" {&alimhulk_txt($dico);} 
		## 26/04/2013 MB : ajout option bofip pour alimenter uniquement Bofip (sans les autres sources)
		case "bofip" {&alimhulk_bofip($dico);}
		## 27/05/2013 AL/MB : ajout option codes pour alimenter uniquement avec les codes EL (sans les autres sources)
		case "codes" {&alimhulk_codes($dico);}
		case "elnet" {&alimhulk_sources($dico);}
		else {&alimhulk_dpxx_gpxx($dico);}
	}

	## on prépare le terrain en ajoutant tout de suite la matiere sur les racines SGML

	## 26/04/2013 MB : ne pas oublier si option bofip ==> modifier en sources car les docs sont tjrs dans le dossier sources
	if ($dico eq "bofip" || $dico eq "codes" || $dico eq "txt" ) {
	$dico = "sources";
	}
	## fin ajouts MB

	&ajouterAttributMatiereSurDossier($hulk_liv_alimhulk.'/'.$dico.'/sgm',&getCodeProdJouve($dico));

	&remettreLesFichiersSgmSurUneLigne($hulk_liv_alimhulk.'/'.$dico.'/sgm');

	if (-d $hulk_liv_alimhulk.'/'.$dico.'/www/pdf'){
	&prefixer_nom_des_fichiers_bulletins_pdf_par_dp($dico,$hulk_liv_alimhulk.'/'.$dico.'/www/pdf');
	&prefixer_nom_des_fichiers_tabspe_pdf_par_dp($dico,$hulk_liv_alimhulk.'/'.$dico.'/www/pdf');
	}

	&poser_la_date_de_copie_alimhulk($hulk_liv_alimhulk.'/'.$dico);
}

## 

exit $g_exitval;
}



# --------------------------------------------------------
# Début du programme
# --------------------------------------------------------

&main();
