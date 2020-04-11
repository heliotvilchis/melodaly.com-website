#!/usr/bin/perl

use strict;
use vars qw(%form %CONF $VERSION $DATA_DIR $FONT);
##### CONFIG ###################################
$VERSION='2.0';   # 05/05/2003
$DATA_DIR='pg-compteur-data';
################################################
##############################################################################
# Ceci est un script CGI en Perl, r�alis� par S�bastien Joncheray.           #
# Vous pouvez l'utiliser gratuitement, � la condition expresse et            #
# non n�gociable de ne pas le modifier du tout, ni de le r�utiliser/recopier #
# en tout ou partie, revendre, louer, redistribuer, etc.                     #
# Un droit d'utilisation gratuite vous est accord�. Tous les autres droits   #
# sont r�serv�s. Toute contrefacon fait l'objet de poursuites. Nous vous     #
# fournissons gratuitement ce script de qualit�,merci de respecter le travail#
# de l'auteur. Pour nous contacter si besoin, voyez sur www.perl-gratuit.com #
##############################################################################
# IL EST PAR-DESSUS TOUT INTERDIT DE MODIFIER LES MENTIONS DE L'AUTEUR       #
# (COPYRIGHT, SITE DE L'AUTEUR,ETC). CELA EST LA CONTREPARTIE DE LA GRATUIT� #
##############################################################################
# De nombreux autres scripts perl en francais, sont disponibles gratuitement #
# sur notre site : http://www.perl-gratuit.com                               #
#                                                                            #
# En cas de difficult�s d'installations veuillez consultez les FAQs et autres#
# sections d'aide sur www.perl-gratuit.com, avant d'envoyer un E-Mail SVP... #
##############################################################################
# Tous droits de modification/distribution/vente strictement r�serv�s        #
##############################################################################
%form=&receive_getpost; &receive_imgsubmit;
&init;

  if (($ENV{'REQUEST_METHOD'} eq 'GET') && ($ENV{'QUERY_STRING'} eq '')) { &print_htmlheader; print("Appel sans param�tres..."); exit(0); }
  # en-tetes de r�ponse
  print "Cache-Control: no-store, no-cache\n";  # s�curit�
  print "Pragma: no-cache\n";                   # s�curit�
  print "Content-Type: application/x-javascript; charset=iso-8859-1\n";
  print "\n";

  # v�rif. referer tout de suite, si besoin :
  if (($ENV{'HTTP_REFERER'} ne '') && ($CONF{'REFERERS'} ne '')) {
    my $buf=join '|',map{quotemeta($_)} split /\|/,$CONF{'REFERERS'};
    if ($ENV{'HTTP_REFERER'}!~ /^(?:http|https|ftp)\:\/\/(?:www\.)*(?:$buf)/) {
      $ENV{'HTTP_REFERER'}=~ /^(?:http|https|ftp)\:\/\/(?:www\.)*([^\/\\\:]+)/;
      &print_js("[appel-compteur:Site r�f�rant refus�($1)]");
    }
  }
  
  # v�rif compteur demand� valide
  my $counter=$form{'counter'};
  if ($counter eq '') {&print_js("[appel-compteur:compteur non pr�cis�]"); exit(0);}
  if (! exists($CONF{"COUNTER_$counter"})) { &print_js("[appel-compteur:compteur <b>$form{'counter'}</b> non d�fini]");}
  
  # incr�mente compteur, keep last 10 IPs
  open (COUNTRW,"+<$DATA_DIR/counter_$counter.dat") || (&print_js("[appel-compteur: Impossible de lire-�crire dans le fichier-compteur]"));
  eval{flock(COUNTRW,2);};
  my ($nb,@lastips)=split(/\|/,<COUNTRW>);
  my $remote_addr=quotemeta($ENV{'REMOTE_ADDR'});
  if (! grep(/^$remote_addr$/,@lastips) ) {
    $nb++;
    unshift(@lastips,$ENV{'REMOTE_ADDR'});
    splice(@lastips,10);
    seek(COUNTRW,0,0);
    print COUNTRW (join '|',($nb,@lastips));
    truncate(COUNTRW,tell(COUNTRW));
  }
  close(COUNTRW);
  
  # Affiche compteur
  my %counter=(split(/\|\|/,$CONF{"COUNTER_$counter"}));
  if ($counter{'type'} eq 'text') {
    &print_js("<span style=\"background-color: $counter{'type_text_bgcolor'}\"><font face=\"$counter{'type_text_face'}\" size=\"$counter{'type_text_size'}\" color=\"$counter{'type_text_color'}\">".($counter{'type_text_bold'} and '<b>').($counter{'type_text_italic'} and '<i>').($counter{'type_text_underlined'} and '<u>')."&nbsp;$nb $counter{'type_text_msg'}&nbsp;".($counter{'type_text_underlined'} and '</u>').($counter{'type_text_italic'} and '</i>').($counter{'type_text_bold'} and '</b>')."</font></span>");
  } elsif ($counter{'type'} eq 'images') {
    &print_js(join '', map{"<img src=\"$counter{'type_images_baseurl'}$_.gif\" border=\"0\">"} split //,$nb);
  } elsif ($counter{'type'} eq 'logo') {
    &print_js("<img src=\"$counter{'type_logo_url'}\" border=\"0\">");
  } elsif ($counter{'type'} eq 'hidden') {
    &print_js("");
  } else {
    &print_js("[appel-compteur: type non reconnu]");
  }



1;
################### FIN ! ######################
################################################














################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub receive_getpost {
# 2002-09-20
my (%postdata,$data,$pair);

  $data='';
  if ($ENV{'REQUEST_METHOD'} eq 'POST') {
    my $len=$ENV{'CONTENT_LENGTH'};
    if (read(STDIN,$data,$len) != $len) {&print_htmlheader;print ("<H1>error reading post data </H1>"); die("Error reading 'POST' data\n"); }
  } elsif ($ENV{'REQUEST_METHOD'} eq 'GET') {
    $data=$ENV{'QUERY_STRING'};
  }

  foreach $pair (split('&',$data)) {
    my ($name,$value)=split('=',$pair);
    $name=~ tr/\0//d;  $value=~ tr/\0//d;
    $name =~ tr/+/ /; $name =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
    $value=~ tr/+/ /; $value=~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
    $postdata{$name}=$value;
  }
  return %postdata;
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub receive_imgsubmit {
# 23/11/2001
my ($key);

  foreach $key(keys(%form)) {
    if ($key=~ s/\.x$//) {
      delete($form{"$key\.x"});
      if ($key=~ /([^\.]+)\.(.+)/) {
        $form{"$1"}="$2";
      } else {
        $form{$key}="1";
      }
    }
    if ($key=~ /\.y$/) { delete($form{$key}); }
  }
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub formfield_encode {
# 27/01/2002
my ($s)=@_;
  $s=~ s/&/&amp;/gso;
  $s=~ s/</&lt;/gso;
  $s=~ s/>/&gt;/gso;
  $s=~ s/"/&quot;/gso;
  $s;
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub print_js {
my ($msg)=@_;
$msg =~ s/\"/\\"/gs; $msg=~ s/\n//gs;  print qq|document.write("$msg");document.close();|;
exit(0);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub print_htmlheader {
  print "Content-type: text/html\n\n" unless ($CONF{'headers_sent'});
  $CONF{'headers_sent'}=1;
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################











################################################
#######                                  #######
#######          ADMINISTRATION          #######
#######                                  #######
################################################
sub init {

  %CONF=();
  $CONF{'CGI_NAME'}='PG-Compteur';              # Nom du CGI: NE PAS CHANGER SINON ERREURS...(noms images)
  $CONF{'CGI_DESC'}="Compteur multifonctions";  # Description du CGI: NE PAS CHANGER SINON ERREURS...
  $CONF{'IMGCGI_URL'}='http://img-scripts.perl-gratuit.com';
  $CONF{'SERVER_NAME'}=($ENV{'SERVER_NAME'} || $ENV{'HTTP_HOST'});
  $CONF{'CGI_URL'}=($ENV{'REQUEST_URI'} || $ENV{'SCRIPT_NAME'});
  $CONF{'CGI_URL'}=~ s/\?.*//gs;                
  $CONF{'CGI0_URL'}="http://".$CONF{'SERVER_NAME'}.$CONF{'CGI_URL'}; # URL compl�te, � utiliser pour visiteurs only (valeur par d�faut)
  
  $FONT="<font face=\"Arial\" size=\"2\">";


  ## V�rif que le r�pertoire des donn�es existe ##
  if (! -e "$DATA_DIR") {
    &msg_fin("ERREUR !","Pour faire fonctionner ce CGI, il vous faut cr�er, dans le r�pertoire o� se trouve
                ce script, le sous-r�pertoire <b>$DATA_DIR</b><br>
                N'oubliez pas de lui attribuer CHMOD 777 (tous droits de lecture,�criture,�x�cution)
                si votre serveur est de type Unix.<br>
		Pour plus d'informations sur 'CHMOD', voyez sur notre site dans les fiches pratiques/FAQ.");
  }

  ## V�rif que le fichier de configuration existe ##
  if (! -e "$DATA_DIR/config.dat") {
    open(TESTW,">$DATA_DIR/config.dat") || (&msg_fin("ERREUR !","Impossible de cr�er le fichier <b>$DATA_DIR/config.dat</b> : $!<br> V�rifiez le CHMOD 777 du r�pertoire <b>$DATA_DIR</b>"));
    close(TESTW);
    eval{ chmod(0777,"$DATA_DIR/config.dat");};
    &msg_fin("Auto-installation",qq|
            <p align="center"><font face="Arial" size="3" color="#800000"><b>Bienvenue dans l'auto-installation de &quot;$CONF{'CGI_NAME'}&quot; !</b></font></p>
            <blockquote><p align="justify">$FONT Vous �x�cutez ce script CGI Perl pour la premi�re fois.
             Afin de faciliter la mise en place de ce script sur votre site, l'installation-configuration
             est guid�e et automatis�e par �tapes successives. Un fichier de configuration va �tre cr��,
             un choix de mot de passe administrateur vous sera demand�, puis une page de choix de configuration
             vous sera pr�sent�e. Nous vous conseillons fortement ensuite de consulter la section de documentation
             inclue.<br>&nbsp;<br>
             Toute cette proc�dure vous permet une mise en place ais�e, sans besoin d'intervenir manuellement
             dans les fichiers et r�pertoires de donn�es de ce script.</font></p></blockquote>
            <p align="center">$FONT<i>Veuillez maintenant actualiser cette page pour continuer SVP...<br>
              (cliquez sur le bouton &quot;Actualiser&quot; de votre navigateur)</i></font></p>|);
  }
  ## V�rif que le fichier mot de passe existe ##
  if (! -e "$DATA_DIR/passwd.dat") {
    open(TESTW,">$DATA_DIR/passwd.dat") || (&msg_fin("ERREUR !","Impossible de cr�er le fichier <b>$DATA_DIR/passwd.dat</b> : $!<br> V�rifiez le CHMOD 777 du r�pertoire <b>$DATA_DIR</b>"));
    close(TESTW);
    eval{ chmod(0777,"$DATA_DIR/passwd.dat");};
    &msg_fin("Auto-installation",qq|
            <p align="center"><font face="Arial" size="3" color="#800000"><b>Conditions d'utilisation gratuite :</b></font></p>
            <blockquote><p align="justify">$FONT Au bas des pages g�n�r�es par ce script vous verrez un copyright
             et la mention de l'auteur (nom et lien vers notre site).<br>
             Un droit d'utilisation gratuite de ce script CGI Perl vous est accord� � la condition expresse
             de ne pas le modifier du tout (y compris et tout particuli�rement ces copyrights et mentions de
             l'auteur), ni de le r�utiliser/recopier en tout ou partie, revendre, louer, redistribuer, etc.
             Tous les droits autres que l'utilisation gratuite sont r�serv�s (nous contacter au besoin).<br>&nbsp;<br>
             Tout simplement, merci de respecter le travail de l'auteur afin que nous puissions continuer
             � vous proposer de tels scripts.</font></p></blockquote>
            <p align="center">$FONT<i>Veuillez maintenant actualiser cette page pour continuer SVP...<br>
              (cliquez sur le bouton &quot;Actualiser&quot; de votre navigateur)</i></font></p>|);
    
  }
  ## V�rif que le r�pertoire des donn�es est prot�g� ##
  if (!-e "$DATA_DIR/.htaccess") {
    open(HTW,">$DATA_DIR/.htaccess") || (&msg_fin("ERREUR !","Impossible de cr�er le fichier <b>$DATA_DIR/.htaccess</b> : $!<br> V�rifiez le CHMOD 777 du r�pertoire <b>$DATA_DIR</b>"));
    print HTW "<Limit GET POST>\norder deny,allow\ndeny from all\n</Limit>\n";
    close(HTW);
    eval{ chmod(0666,"$DATA_DIR/.htaccess");};
    &msg_fin("AUTO-PROTECTION DES DONNEES",qq|
            <p align="center"><font face="Arial" size="3" color="#800000"><b>S�curit� de votre r�pertoire des donn�es</b></font></p>
            <blockquote><p align="justify">$FONT Certains serveurs peu ou mal s�curis�s permettent l'acc�s,
             le listing et la consultation des fichiers � l'int�rieur de la section &quot;cgi-bin&quot; des sites
             h�berg�s.<br>&nbsp;<br>
             Afin d'emp�cher tout acc�s par la navigateur dans votre r�pertoire des donn�es <b>$DATA_DIR</b>
             un fichier sp�cial &quot;.htaccess&quot; vient d'�tre automatiquement cr�� avec les
             directives-serveurs ad�quates.<br>&nbsp;<br>
             Selon votre serveur, il se peut que vous ne puissiez pas voir le .htaccess par FTP. Dans ce cas,
             consultez la page d'informations correspondante dans la section
             <a href="http://www.perl-gratuit.com/fiches/" target="_blank"><b>Fiches Pratiques</b></a> de
             notre site.</font></p></blockquote>
            <p align="center">$FONT<i>Veuillez maintenant actualiser cette page pour continuer SVP...<br>
              (cliquez sur le bouton &quot;Actualiser&quot; de votre navigateur)</i></font></p>|);
  }
  ## Chargement configuration
  open (CONFR,"$DATA_DIR/config.dat") || &msg_fin("ERREUR !", "Impossible de lire le fichier <b>$DATA_DIR/config.dat</b>: $!");
  eval{flock(CONFR,2);};
  while (<CONFR>) {
    chomp($_);
    if ( ($_ ne '') && ($_!~ /^#/) && ($_=~ /^([^\s]+)\s+(.*)/) ) {
      $CONF{"$1"}="$2";
      $CONF{"$1"}=~ s/\|\\n\|/\n/gs;
    }
  }
  close (CONFR);
  ## Chargement mot de passe:
  open (PASSR,"$DATA_DIR/passwd.dat") || (&msg_fin("ERREUR !","Impossible de lire le fichier <b>$DATA_DIR/passwd.dat</b>: $!"));
  $CONF{'CPASSWD'}=<PASSR>;
  close(PASSR);
  chomp($CONF{'CPASSWD'});
  ## V�rif mot de passe fix�
  if ($CONF{'CPASSWD'} eq '') {  (($form{'ORDadmin_changepass_do'} eq '') && (&admin_changepass) ) || (&admin_changepass_do); }
  ## OPTIONNAL STUFF :
  #  nothing
  
  ## L'administrateur veut entrer ? ##
  if($ENV{'QUERY_STRING'} eq 'admin') { 
    &msg_fin("ENTREE ADMINISTRATEUR",qq|<center><form action="$CONF{CGI_URL}" METHOD="POST">
                                     Mot de Passe : <input type="PASSWORD" name="PASSWD"><br>&nbsp;<br>
                                     <input type="submit" value="Entr�e"></form></center>|);
  }
  ## L'administrateur est d�j� entr� ##
  if ($form{'PASSWD'}) {                        # On v�rifie le mot de passe s'il y en a un
    if (crypt($form{'PASSWD'},'aa') ne $CONF{'CPASSWD'}) {
      sleep(3);
      &msg_fin ("ACCES ADMINSTRATEUR REFUSE","<b>Le mot de passe n'est pas correct !</b><br>
                Retournez � la page pr�c�dente pour retenter...<br>
                Si vous ne parvenez pas � vous souvenir de votre mot de passe, une seule chose � faire : par FTP,
                supprimez le fichier <b>&quot;$DATA_DIR/passwd.dat&quot;</b> puis rendez-vous � l'URL de ce script
                pour fixer un nouveau mot de passe.");
    }
    ## V�rif param�trage effectu� ##
    if (!$CONF{'config_param'}) {    ( ($form{'ORDadmin_param_do'} eq '') && (&admin_param) ) || (&admin_param_do);  }
    &admin;
    exit(0);
  }
  ## sinon retour � l'utilisation publique normale
}
################################################
################################################
sub msg_fin {
my ($titre,$tip)=@_;
my ($d1,$d2);

  &print_htmlheader;
  ## ATTENTION, si vous modifiez ou supprimez les lignes ci-dessous, vous ne #
  ## respectez pas les conditions d'utilisation gratuite de ce programme, et #
  ## vous vous en servez de mani�re ill�gale ! Merci de respecter le travail #
  ## de l'auteur !        Merci de votre compr�hension.                      #
  print qq|<html>
  <head>
   <title>$CONF{CGI_NAME} - Administration</title>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
   <style><!-- A:link {text-decoration: none; color: #0000FF}  A:visited {text-decoration: none; color: #0000FF}  A:hover {text-decoration: underline; color: #0000FF}  --></style>
  </head>
  <body bgcolor="#FFFFFF" text="#000000" link="#0000FF" vlink="#0000FF" alink="#0000FF">
  <p>&nbsp;</p>
  <div align="center"><center>
  <table border="0" width="80%" cellspacing="1" cellpadding="0">
    <tr><td width="100%" bgcolor="#E7BD30" align="center" style="border: 1px solid rgb(0,0,128)"><font face="Arial" size="3" color="#000080"><b>$CONF{'CGI_NAME'} : <i>$titre</i></b></font></td></tr>
    <tr><td width="100%" bgcolor="#DDDDDD" style="border: 1px solid rgb(0,0,0); padding: 5px"><font face="Arial" size="2"><p>&nbsp;</p>$tip<p>&nbsp;</p></font></tr>
    <tr><td width="100%" bgcolor="#E7BD30" align="center" style="border: 1px solid rgb(0,0,128)"><font face="Arial" size="1" color="#000080"><b>Script CGI Perl gratuit disponible sur <a href="http://www.perl-gratuit.com">perl-gratuit.com</a>. v$VERSION &copy;</b></font></td></tr>
  </table></center></div>
  </body>
  </html>|;
  exit(0);
  ## ATTENTION, si vous modifiez ou supprimez les lignes ci-dessus, vous ne  #
  ## respectez pas les conditions d'utilisation gratuite de ce programme, et #
  ## vous vous en servez de mani�re ill�gale ! Merci de respecter le travail #
  ## de l'auteur !        Merci de votre compr�hension.                      #
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin {

  if ($form{'ORDadmin_changepass'})         { &admin_changepass;
  } elsif ($form{'ORDadmin_changepass_do'}) { &admin_changepass_do;
  } elsif ($form{'ORDadmin_version'})       { &admin_version;
  } elsif ($form{'ORDadmin_info'})          { &admin_info;
  } elsif ($form{'ORDadmin_param'})         { &admin_param;
  } elsif ($form{'ORDadmin_param_do'})      { &admin_param_do;
  } elsif ($form{'ORDadmin_editcounter'})   { &admin_editcounter($form{'ORDadmin_editcounter'});
  } elsif ($form{'ORDadmin_editcounter_do'}){ &admin_editcounter_do;
  } elsif ($form{'ORDadmin_delcounter'})    { &admin_delcounter;
  } elsif ($form{'ORDadmin_htmlcode'})      { &admin_htmlcode($form{'ORDadmin_htmlcode'});
  } else                                    { &admin_menu;
  }
  exit(0);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_menu {
my (%tmpl,$counter)=();

  $tmpl{'REFERERS'}=join ', ', (split(/\|/,$CONF{'REFERERS'}));
  $tmpl{'REFERERS'} ||='Tous !';

  foreach $counter (map{s/^COUNTER_//; $_;} sort{lc($a) cmp lc($b)} grep(/^COUNTER_.+/, keys %CONF)) { # plein d'action en une seule ligne d�licate...
    my $nb='0';
    if (-e "$DATA_DIR/counter_$counter.dat") {
      open (COUNTRW,"+<$DATA_DIR/counter_$counter.dat") || (&msg_fin("ERREUR !","Impossible de lire-�crire dans le fichier <b>$DATA_DIR/counter_$counter.dat</b> : $!<br> V�rifiez le CHMOD 666 de ce fichier.")); # '+<' fait office de test de chmod r+w...
      eval{flock(COUNTRW,2);};
      ($nb,undef)=split(/\|/,<COUNTRW>);
      close(COUNTRW);
    } else {
      open(COUNTW,">$DATA_DIR/counter_$counter.dat") || (&msg_fin("ERREUR !","Impossible de cr�er le fichier <b>$DATA_DIR/counter_$counter.dat</b> : $!<br> V�rifiez le CHMOD 777 du r�pertoire <b>$DATA_DIR</b>"));
      close(COUNTW);
      eval{ chmod(0666,"$DATA_DIR/counter_$counter.dat");};
    }
    $tmpl{'list'}.="<tr>";
    $tmpl{'list'}.="<td bgcolor=\"#EEEEEE\">$FONT &nbsp;$counter &nbsp;</font></td>";
    $tmpl{'list'}.="<td bgcolor=\"#EEEEEE\" align=\"right\">$FONT &nbsp;".int($nb)." &nbsp;</font></td>";
    $tmpl{'list'}.="<td nowrap>&nbsp;<input type=\"submit\" style=\"font-size: xx-small\" name=\"ORDadmin_editcounter.$counter.x\" value=\"D�tails/Modifier\">&nbsp;<input type=\"submit\" style=\"font-size: xx-small\" name=\"ORDadmin_htmlcode.$counter.x\" value=\"code HTML & Test\"></td>";
    $tmpl{'list'}.="</tr>\n";
  }
  if ($tmpl{'list'} eq '') { $tmpl{'list'}="<tr><td colspan=\"3\" align=\"center\">$FONT<i>Aucun compteur configur� actuellement.<br>Cliquez sur &quot;Nouveau compteur...&nbsp; ci-dessous</i></font></td></tr>";}
  
  &msg_fin("Menu Administration",qq|
          <div align="center"><center>
          <table border="0" cellspacing="1" cellpadding="0">
           <tr> <td colspan="2" align="center"><font face="Arial" size="2" color="#800000"><b>Vos param�tres :</b></font></td> </tr>
           <tr> <td valign="top">$FONT Sites r�f�rants autoris�s  : </font></td> <td>$FONT$tmpl{REFERERS}</font></td> </tr>
          </table>
          <br>
          
          <form method="POST" action="$CONF{CGI_URL}">
          <input type="hidden" name="PASSWD" VALUE="$form{PASSWD}">
          <table border="0" cellpadding="1" cellspacing="1">
          <tr align="center">
           <td><font face="Arial" size="2" color="#800000"><b>Compteur </b></font></td>
           <td><font face="Arial" size="2" color="#800000"><b>Valeur </b></font></td>
           <td>&nbsp;</td>
          </tr>
          $tmpl{'list'}
          </table>
          <br>
          
          <table border="0" cellspacing="1">
          <tr><td align="center"><B><font face="Arial" color="#800000">Menu :</font></B></td></tr>
          <tr><td style="border: 1px solid #800000; padding: 8px"><font face="Arial" size="2">
            <input type="submit" value="&gt;&gt;" name="ORDadmin_editcounter.new.x"> Nouveau compteur...<br>
            <input type="submit" value="&gt;&gt;" name="ORDadmin_menu"> Actualiser cette page
            <hr size="1" color="#800000">
            <input type="submit" value="&gt;&gt;" name="ORDadmin_param"> Modifier vos param�tres.<br>
            <input type="submit" value="&gt;&gt;" name="ORDadmin_changepass"> Modifier votre mot de passe.<br>
            <input type="submit" value="&gt;&gt;" name="ORDadmin_version"> Derni�re version disponible.<br>
            <input type="submit" value="&gt;&gt;" name="ORDadmin_info"> DOCUMENTATION / INFORMATIONS A LIRE
            </font></td>
          </tr>
          </table>
          </form>
          </center></div>|);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_changepass {

  &msg_fin("Modification du mot de passe Administrateur",
           "<p align=\"center\">$FONT Choisissez votre nouveau mot de passe Administrateur de ce script (4 � 8 caract�res).</font></p>
            <form action=\"$CONF{'CGI_URL'}\" method=\"POST\">
            <input type=\"hidden\" name=\"PASSWD\" value=\"$form{'PASSWD'}\">
            <div align=\"center\"><center><table border=\"0\">
            <tr><td>$FONT Nouveau mot de passe :</font></td> <td><input type=\"text\" name=\"new_passwd\" size=\"8\"></td></tr>
            <tr><td>$FONT Nouveau mot de passe (confirmation) :</font></td> <td><input type=\"text\" name=\"new_passwdbis\" size=\"8\"></td></tr>
            <tr><td colspan=\"2\" align=\"center\"> <input type=\"submit\" name=\"ORDadmin_changepass_do\" value=\"Enregistrer ce nouveau mot de passe\"> <input type=\"submit\" value=\"Annuler\"> </td></tr>
            </table></center></div></form>\n");
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_changepass_do {

  if (length($form{'new_passwd'}) < 4)               { &msg_fin("ERREUR !","Le mot de passe <b>$form{new_passwd}</b> fait moins de 4 caract�res, ce qui est dangereux !");}
  if ($form{'new_passwd'} ne $form{'new_passwdbis'}) { &msg_fin("ERREUR !","Les deux cases de mot de passe ne sont pas identiques");}

  $CONF{'CPASSWD'}=crypt($form{'new_passwd'},'aa');
  open (PASSW,">$DATA_DIR/passwd.dat") || (&msg_fin("ERREUR !","Impossible d'enregistrer dans le fichier <b>$DATA_DIR/passwd.dat</b> ($!), veuillez v�rifier le chmod 777 du r�pertoire <b>$DATA_DIR</b>: $!"));
  print PASSW "$CONF{'CPASSWD'}";
  close (PASSW);
  eval{ chmod(0666,"$DATA_DIR/passwd.dat");};

  $form{'PASSWD'}=$form{'new_passwd'};
  &msg_fin("Mot de passe Administrateur modifi�",
           "<blockquote>
             <p>$FONT Le mot de passe pour l'acc�s Administrateur a �t� modifi� et est
                maintenant <font color=\"#FF0000\">$form{'new_passwd'}</font>. Attention, il est sauvegard� de fa�on crypt�e.
                Vous ne pourrez pas (ce programme non plus) le d�crypter. Si vous l'oubliez, lorsque
                vous tenterez d'acc�der ici avec un mauvais mot de passe, un message vous expliquera comment faire.
             </font></p>
             <center><form action=\"$CONF{'CGI_URL'}\" method=\"POST\"><input type=\"hidden\" name=\"PASSWD\" value=\"$form{'new_passwd'}\"><input type=\"submit\" value=\"Cliquez ici pour continuer\"></form></center>
             </blockquote>\n");
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_param {
my (%tmpl);

  if (!$CONF{'config_param'}) {
    $CONF{'REFERERS'}=$ENV{'SERVER_NAME'};
    $CONF{'REFERERS'}=~ s/^www\.//gs;
  }

  $tmpl{'CGI0_URL'}=&formfield_encode($CONF{'CGI0_URL'});
  $tmpl{'REFERERS'}=join "\n",(split(/\|/, $CONF{'REFERERS'}));

  &msg_fin("Configuration",qq|
          <form action="$CONF{CGI_URL}" method="POST">
          <input type="hidden" name="PASSWD" value="$form{'PASSWD'}">
          <div align="center"><center>
          <table width="80%" border="0" cellpadding="5">
          <tr valign="top">
            <td>$FONT<B>URL compl�te exacte de ce script :</b><br>
             Merci de v�rifier que l'URL indiqu�e ici est correcte.
             C'est celle-ci qui sera utilis�e pour le code HTML � ins�rer dans vos pages web.</font></td>
            <td><input type="text" name="CGI0_URL" size="20" value="$tmpl{CGI0_URL}"></td>
          </tr><tr valign="top">
            <td colspan="2">$FONT<B>Sites r�f�rants autoris�s :</B><br>
             Indiquez ici la liste des sites autoris�s � utiliser ce script de compteurs.
             Si un site tente d'appeler un de vos compteurs, un message d'erreur apparaitra.
             Laissez vide si vous souhaitez autoriser tout site � utiliser ce script (fortement d�conseill�).<br>
             <u>Mettez un nom de domaine complet seul par ligne, sans "http://", ni "www."</u><br>
             Exemple: <i>yahoo.fr</i> , ou:  <i>mail.yahoo.fr</i></font><br>
            <textarea name="REFERERS" cols="60" rows="4" wrap="OFF">$tmpl{REFERERS}</textarea><br>&nbsp;</td>
          </tr>
          </table>
          
          <input type="submit" name="ORDadmin_param_do" value="VALIDER !"> <input type="submit" name="ORDadmin_menu" value="Annuler">
          </center></div>
          </form>|);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_param_do {

  # CGI0_URL
  if ($form{'CGI0_URL'} eq '') {     &msg_fin("ERREUR !","Vous n'avez pas indiqu� l'URL de ce script.");}
  if ($form{'CGI0_URL'}!~ m|^https*://|) { &msg_fin("ERREUR !","L'URL de ce script doit commencer par <i>http://</i> ou <i>https://</i>");}
  $CONF{'CGI0_URL'}=$form{'CGI0_URL'};
  # REFERERS
  $form{'REFERERS'}=~ s/\r\n/\n/gs;
  $form{'REFERERS'}=~ s/^\s+|\s+$//gs;
  $form{'REFERERS'}=~ s/\n\n+/\n/gs;
  $form{'REFERERS'}=~ s/[ \t\r]+//gs;
  foreach (split(/\n+/,$form{'REFERERS'})) {
    if (/([^a-zA-Z0-9\-\_\.])/) { &msg_fin("ERREUR !","La liste des sites r�f�rants contient au moins un caract�re incorrect : <b>$1</b><br> Utilisez uniquement les lettres de l'alphabet, les chiffres ou le tiret (-) ou le soulign�(_) ou le point(.)");}
  }
  $CONF{'REFERERS'}=join('|',(split(/\n+/,$form{'REFERERS'})));
  # SAVE IT'S DONE:
  $CONF{config_param}=1;
  
  &admin_param_saveconf;

  &msg_fin("Configuration",
           "<p align=\"center\">$FONT Param�tres de configuration enregistr�s avec succ�s !<br> </font></p>
            <center><form action=\"$CONF{'CGI_URL'}\" method=\"POST\"><input type=\"hidden\" name=\"PASSWD\" value=\"$form{PASSWD}\"><input type=\"submit\" name=\"ORDadmin_menu\" value=\"Cliquez ici pour continuer\"></form></center>");
}
################################################
sub admin_param_saveconf {
  ## ENREGISTREMENTS PARAMS ##
  eval{chmod(0777,"$DATA_DIR/config.dat");};
  open (CONFW,">$DATA_DIR/config.dat") ||  (&msg_fin("ERREUR !","Impossible de r��crire <b>$DATA_DIR/config.dat</b> : $!<br> Merci de mettre chmod 777 manuellement � ce fichier et au r�pertoire... "));
  foreach ('config_param','CGI0_URL','REFERERS',(sort{lc($a) cmp lc($b)}(grep(/^COUNTER_.+/, keys %CONF)))) {
    $CONF{$_}=~ s/\n/\|\\n\|/gs;
    print CONFW ("$_\t$CONF{$_}\n");
  }
  close (CONFW);
  ## /ENREGISTREMENTS PARAMS ##
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_version {
my %tmpl=();
  $tmpl{'CGI_NAME_fted'}=lc($CONF{CGI_NAME}); # formatted
  $tmpl{'CGI_NAME_fted'}=~ s/\s/_/gs;

  &msg_fin("Derni�re version disponible",qq|
    <blockquote>
      <p><font face="Arial" size="2">Cette page vous indique <u>en temps r�el</u> s'il existe
      une version plus r�cente de ce script CGI Perl sur notre site perl-gratuit.com. Si vous constatez
      que c'est le cas, vous pouvez aller y consulter le d�tail des ajouts ou corrections
      �ventuelles de ce CGI, et t�l�charger/installer la nouvelle version.</font></p>
    </blockquote>
    <div align="center"><center>
    <table border="0" cellpadding="2" cellspacing="1">
      <tr>
        <td><font face="Arial" size="2"><b>Version utilis�e ici :</b></font></td>
        <td><font face="Arial" size="2" color="#0000FF"><b>$VERSION</b></font></td>
      </tr> <tr>
        <td><font face="Arial" size="2"><b>Derni�re version disponible : &nbsp; </b></font></td>
        <td><img src="$CONF{'IMGCGI_URL'}/$tmpl{CGI_NAME_fted}_vnumber.gif" border="0"></td>
      </tr>
    </table>
    <p>$FONT
     Remarque �ventuelle sur la derni�re version :<br><img src="$CONF{'IMGCGI_URL'}/$tmpl{CGI_NAME_fted}_vnote.gif" border="0"><br> &nbsp;<br>
     Vous trouverez la derni�re version disponible sur <a href="http://www.perl-gratuit.com" target="_blank">Perl-Gratuit.com</a>
    </font></p>
    <form action="$CONF{CGI_URL}" METHOD="POST"><input type="hidden" name="PASSWD" value="$form{PASSWD}"><input type="submit" value="Retour Menu"></form>
    </center></div>|);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_info {
my (%tmpl)=();

  $tmpl{'form'}=&formfield_encode($CONF{'theform'});

  &msg_fin("Documentation / Informations � lire",qq|
    <p align="center"><font face="Arial" color="#800000" size="3"><b>Informations sur l'utilisation de $CONF{CGI_NAME} :</b></font></p>
    
    <p><font face="Arial" size="2"><font color="#800000"><b>Acc�s � l'administration :</b></font><br>
     Pour acc�der � la section d'administration de $CONF{CGI_NAME} rendez-vous � l'URL exacte : <br>
     <a href="http://$ENV{SERVER_NAME}$CONF{CGI_URL}?admin">http://$ENV{SERVER_NAME}$CONF{CGI_URL}?admin</a><br>
     Mettez cette URL dans vos favoris pour ne pas l'oublier ! Votre mot de passe sera ensuite demand�.</font></p>
    
    <p><font face="Arial" size="2"><font color="#800000"><b>Int�gration dans votre site :</b></font><br>
    - Il suffit de recopier dans la ou les pages HTML de votre choix, le code d'insertion de compteur indiqu�
    dans la section "Code HTML & Test" du compteur concern�, page suivante.
    (cela est � ins�rer dans le <u>code source</u> de(s) page(s) HTML.<br>
    - Note : ce script comptabilise les visiteurs et non pas le nombre d'affichages. Il est donc
    normal que le compteur ne s'incr�mente pas lorsque vous actualisez une page le contenant. Il s'incr�mentera
    la prochaine fois qu'une autre personne (autre adresse IP) se rendra sur une des pages utilisant le compteur
    concern�.<br>
    - Note : Pour une excellente fiabilit�, ce script conserve toujours pour chaque compteur, les adresses IP
    des 10 derniers visiteurs (au lieu de 1 seul habituellement), afin de ne pas comptabiliser plusieurs fois
    une m�me personne.</font></p>
    
    <p><font face="Arial" size="2"><font color="#800000"><b>Copyright - Licence d'utilisation :</b></font><br>
    Un droit d'utilisation gratuite de ce script CGI Perl vous est accord� � la condition expresse de ne pas
    le modifier du tout, ni de le r�utiliser ou recopier en tout ou partie, revendre, louer, redistribuer, etc.
    Tous les droits autres que l'utilisation gratuite sont r�serv�s (nous contacter au besoin).
    Toute contrefa�on ou autre violation des droits de propri�t� intellectuelle fait l'objet de poursuites.
    IL EST PAR-DESSUS TOUT INTERDIT DE MODIFIER LES MENTIONS DE L'AUTEUR (COPYRIGHT, NOM ET LIEN VERS LE SITE
    DE L'AUTEUR,ETC). CECI EST LA CONTREPARTIE DE LA GRATUIT�.<br>
    Tout simplement, merci de respecter le travail de l'auteur... afin que nous puissions continuer � vous
    proposer de tels scripts CGI Perl.</font></p>
    
    <p><font face="Arial" size="2"><font color="#800000"><b>Nous proposons �galement des scripts PRO :</b></font><br>
    En plus des scripts gratuits disponibles sur Perl-Gratuit.com, nous proposons des scripts PRO
    d�di�s � un usage professionnel dont les principales caract�ristiques sont :<br>
    - aucune mention de l'auteur ni copyright visible par le visiteur.<br>
    - personnalisation compl�te de l'affichage pour une bonne int�gration � votre site.<br>
    - assistance, support technique privil�gi� et ultra-prioritaire, documentation compl�te en ligne.<br>
    - installation offerte sur demande.<br>
    - nombreuses fontionnalit�s suppl�mentaires, etc...<br>
    Pour consulter les scripts PRO disponibles et en acqu�rir �ventuellement une licence,
    merci de vous rendre sur notre autre site: <a href="http://www.perl-pro.com/" target="_blank">Perl-PRO.com</a>
    </font></p>
    
    <center>
     <form action="$CONF{CGI_URL}" method="POST"><input type="hidden" name="PASSWD" value="$form{PASSWD}"><input type="submit" value="Retour Menu"></form>
    </center>
  |);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_editcounter {
my ($counter)=@_;
my (%tmpl,%counter)=();

  $tmpl{'counter'}=$counter;
  if ($counter eq 'new') {
    $tmpl{'newcounter'}='<input type="text" name="newcounter" value="" size="15"><br><i>lettres non accentu�es, chiffres, tiret (-) ou soulign� (_), sans espaces</i>';
    %counter=('type' => 'text',
              'type_text_face'    => 'Arial',
              'type_text_size'    => '2',
              'type_text_color'   => '#FFFFFF',
              'type_text_bgcolor' => '#000000',
              'type_text_msg'     => 'visiteurs',
              'type_text_bold'       => '1',
              'type_text_italic'     => '0',
              'type_text_underlined' => '0');
    $tmpl{'counter_value'}='0';
    $tmpl{'sbm_more'}='';
  } else {
    %counter=(split(/\|\|/,$CONF{"COUNTER_$counter"}));
    $tmpl{'newcounter'}=" &nbsp; <big><b>$counter</b></big>";
    open (COUNTR,"$DATA_DIR/counter_$counter.dat") || (&msg_fin("ERREUR !","Impossible de lire <b>$DATA_DIR/counter_$counter.dat</b> : $!<br> V�rifiez le CHMOD 666 de ce fichier."));
    eval{flock(COUNTR,2);};
    ($tmpl{'counter_value'},undef)=split(/\|/,<COUNTR>);
    close(COUNTR);
    $tmpl{'sbm_more'}='<input type="submit" name="ORDadmin_delcounter" value="Supprimer !">';
  }
  # type : text
  $tmpl{'type_text'}=$counter{'type'} eq 'text' ? ' checked' : '';
  $tmpl{'type_text_face'}   =&formfield_encode($counter{'type_text_face'});
  $tmpl{'type_text_size'}   =&formfield_encode($counter{'type_text_size'});
  $tmpl{'type_text_color'}  =&formfield_encode($counter{'type_text_color'});
  $tmpl{'type_text_bgcolor'}=&formfield_encode($counter{'type_text_bgcolor'});
  $tmpl{'type_text_msg'}    =&formfield_encode($counter{'type_text_msg'});
  $tmpl{'type_text_bold'}   =$counter{'type_text_bold'}==1 ? ' checked' : '';
  $tmpl{'type_text_italic'} =$counter{'type_text_italic'}==1 ? ' checked' : '';
  $tmpl{'type_text_underlined'}=$counter{'type_text_underlined'}==1 ? ' checked' : '';
  # type : images
  $tmpl{'type_images'}=$counter{'type'} eq 'images' ? ' checked' :'';
  $tmpl{'type_images_baseurl'}=&formfield_encode($counter{'type_images_baseurl'});
  # type : logo
  $tmpl{'type_logo'}=$counter{'type'} eq 'logo' ? ' checked' :'';
  $tmpl{'type_logo_url'}=&formfield_encode($counter{'type_logo_url'});
  # type : hidden
  $tmpl{'type_hidden'}=$counter{'type'} eq 'hidden' ? ' checked' :'';
  

  &msg_fin("Configurer un Compteur",qq|
    <div align="center"><center>
    <form method="POST" action="$CONF{CGI_URL}">
    <input type="hidden" name="PASSWD" VALUE="$form{PASSWD}">
    <input type="hidden" name="counter" VALUE="$counter">
    <p align="center">$FONT<big><b><u>Nom du compteur :</u></b></big>  $tmpl{newcounter}</font></p>
    <table width="90%" border="0" cellspacing="1" cellpadding="1">
    <tr><td colspan="2" align="center"><font face="Arial" size="2" color="#800000"><b>Type d'affichage du compteur</b></font></td></tr>
    <tr>
      <td valign="top" nowrap>$FONT<input type="radio" name="type" value="text" $tmpl{type_text}> <b>Texte</b>&nbsp;</font></td>
      <td>$FONT Compteur affich� sous forme de texte, mise en forme ci-dessous.</font><br>
        <table cellpadding="0" cellspacing="0" border="0">
        <tr><td nowrap>$FONT Police de caract�res :  </font></td> <td><input type="text" name="type_text_face"    value="$tmpl{type_text_face}"    size="8">$FONT Exemple : <i>Arial</i>           </font></td></tr>
        <tr><td nowrap>$FONT Taille de caract�res :  </font></td> <td><input type="text" name="type_text_size"    value="$tmpl{type_text_size}"    size="8">$FONT Exemple : <i>2</i>               </font></td></tr>
        <tr><td nowrap>$FONT Couleur de caract�res : </font></td> <td><input type="text" name="type_text_color"   value="$tmpl{type_text_color}"   size="8">$FONT Exemple : <i>#FFFFFF</i> (blanc) </font><a href="javascript://" onclick="window.open('$CONF{IMGCGI_URL}/palette.html','palette','height=450,width=360,menubar=no,scrollbars=no,toolbar=no,location=no,status=no'); return true;"><img src="$CONF{IMGCGI_URL}/palette.gif" border="0" align="absmiddle"></a></td></tr>
        <tr><td nowrap>$FONT Couleur de fond :       </font></td> <td><input type="text" name="type_text_bgcolor" value="$tmpl{type_text_bgcolor}" size="8">$FONT Exemple : <i>#000000</i> (noir)  </font><a href="javascript://" onclick="window.open('$CONF{IMGCGI_URL}/palette.html','palette','height=450,width=360,menubar=no,scrollbars=no,toolbar=no,location=no,status=no'); return true;"><img src="$CONF{IMGCGI_URL}/palette.gif" border="0" align="absmiddle"></a></td></tr>
        <tr><td nowrap>$FONT Texte � afficher apr�s: </font></td> <td><input type="text" name="type_text_msg"     value="$tmpl{type_text_msg}"     size="8">$FONT Exemple : <i>visiteurs</i>       </font></td></tr>
        <tr><td colspan="2" align="center" nowrap>$FONT
          <input type="checkbox" name="type_text_bold" value="1" $tmpl{type_text_bold}>Gras &nbsp; &nbsp; &nbsp;
          <input type="checkbox" name="type_text_italic" value="1" $tmpl{type_text_italic}>Italique &nbsp; &nbsp; &nbsp;
          <input type="checkbox" name="type_text_underlined" value="1" $tmpl{type_text_underlined}>Soulign�
        </td></tr>
        </table>
        &nbsp;<br>
      </td>
    </tr><tr>
      <td valign="top" nowrap>$FONT<input type="radio" name="type" value="images" $tmpl{type_images}> <b>Images</b>&nbsp;</font></td>
      <td>$FONT Compteur utilisant des images de chaque chiffre, pr�par�es par vos soins.<br>
        Indiquez ci-dessous l'URL du r�pertoire contenant les images de chaque chiffre
        (0.gif 1.gif  2.gif ..  9.gif). L'URL doit commencer par <u>http://</u>. Vous trouverez des ensembles
        d'images (0.gif � 9.gif) sous forme de zip � t�l�charger depuis la page de pr�sentation de ce script
        sur notre site web. Ces images sont � installer dans votre site (hors /cgi_bin/)<br>
        URL r�pertoire images : <input type="text" name="type_images_baseurl" value="$tmpl{type_images_baseurl}" size="30"><br>
        &nbsp;</font>
      </td>
    </tr><tr>
      <td valign="top" nowrap>$FONT<input type="radio" name="type" value="logo" $tmpl{type_logo}> <b>Logo fixe</b>&nbsp;</font></td>
      <td>$FONT Compteur affichant toujours un m�me logo ou autre image externe fixe.<br>
        URL logo : <input type="text" name="type_logo_url" value="$tmpl{type_logo_url}" size="30"><br>
        &nbsp;</font>
      </td>
    </tr><tr>
      <td valign="top" nowrap>$FONT<input type="radio" name="type" value="hidden" $tmpl{type_hidden}> <b>Invisible (cach�)</b>&nbsp;</font></td>
      <td>$FONT Compteur n'affichant rien du tout dans la page.<br>
           (�tat visible dans la section d'administration uniquement)</font></td>
    </tr>
    
    <tr><td colspan="2" align="center">&nbsp;<br><font face="Arial" size="2" color="#800000"><b>Valeur du compteur</b></font></td></tr>
    <tr><td colspan="2" align="center">$FONT
         Vous pouvez changer la valeur du compteur ici:
         <input type="text" name="counter_value" value="$tmpl{counter_value}" style="text-align: right" size="8"></font></td>
    </tr>
    </table>
    
    &nbsp;<br>
    <input type="submit" name="ORDadmin_editcounter_do" value="Valider"> &nbsp; 
    <input type="submit" value="Annuler, retour menu">&nbsp; $tmpl{'sbm_more'}
    </form>
    </center></div>|);
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_editcounter_do{
my (%counter)=();
  my $counter=$form{'counter'};

  if ($form{'type'} eq 'text') {
    if ($form{'type_text_face'} eq '') { &msg_fin("ERREUR !","Compteur type texte: vous n'avez pas indiqu� la police de caract�res � utiliser.");}
    if ($form{'type_text_size'} eq '') { &msg_fin("ERREUR !","Compteur type texte: vous n'avez pas indiqu� la taille de caract�res � utiliser.");}
    if ($form{'type_text_color'} eq '') { &msg_fin("ERREUR !","Compteur type texte: vous n'avez pas indiqu� la couleur de caract�res � utiliser.");}
    if ($form{'type_text_bgcolor'} eq '') { &msg_fin("ERREUR !","Compteur type texte: vous n'avez pas indiqu� la couleur de fond � utiliser.");}
    foreach('type_text_face','type_text_size','type_text_color','type_text_bgcolor','type_text_bold','type_text_italic','type_text_underlined','type_text_msg') {$counter{$_}=$form{$_};$counter{$_}=~ s/\|\|//gs;}
    
  } elsif ($form{'type'} eq 'images') {
    if ($form{'type_images_baseurl'}!~ /^(http|https)\:\/\/.+/) { &msg_fin("ERREUR !","Compteur type images : l'url du r�pertoire des images doit commencer par http:// ou https://");}
    if ($form{'type_images_baseurl'}=~ /(\|\||\")/) { &msg_fin("ERREUR !","Compteur type images, url : Caract�re non autoris� ici : <b>$1</b>");}
    $form{'type_images_baseurl'}.='/' if ($form{'type_images_baseurl'}!~ /\/$/);
    $counter{'type_images_baseurl'}=$form{'type_images_baseurl'};
    
  } elsif ($form{'type'} eq 'logo') {
    if ($form{'type_logo_url'}!~ /^(http|https)\:\/\/.+/) { &msg_fin("ERREUR !","Compteur type logo fixe : l'url du logo doit commencer par http:// ou https://");}
    if ($form{'type_logo_url'}=~ /(\|\||\")/) { &msg_fin("ERREUR !","Compteur type logo fixe, url : Caract�re non autoris� ici : <b>$1</b>");}
    $counter{'type_logo_url'}=$form{'type_logo_url'};
    
  } elsif ($form{'type'} eq 'hidden') {
    # nothing
    
  } else {
    &msg_fin("ERREUR !","Vous n'avez pas s�lectionn� le type d'affichage du compteur.");
  }
  $counter{'type'}=$form{'type'};
  

  if ($counter eq 'new') {
    if ($form{'newcounter'} eq '') { &msg_fin("ERREUR !","Nom du nouveau compteur vide...");}
    if ($form{'newcounter'}=~ /([^a-zA-Z0-9\-\_])/) { &msg_fin("ERREUR !","Nom du compteur : Caract�re non autoris� ici : <b>$1</b>");}
    if ($form{'newcounter'} eq 'new') { &msg_fin("ERREUR !","Nom du compteur : 'new' est r�serv�, ce code ne peut pas �tre utilis�.");}
    if (exists($CONF{"COUNTER_$form{newcounter}"})) { &msg_fin("ERREUR !"," Ce nom de compteur <b>$form{newcounter}</b> est d�j� utilis�. Veuillez en choisir un autre SVP.");}
    $counter=$form{newcounter};
    # creation fichier-compteur
    open(COUNTW,">$DATA_DIR/counter_$counter.dat") || (&msg_fin("ERREUR !","Impossible de cr�er le fichier <b>$DATA_DIR/counter_$counter.dat</b> : $!<br> V�rifiez le CHMOD 777 du r�pertoire <b>$DATA_DIR</b>"));
    close(COUNTW);
    eval{ chmod(0666,"$DATA_DIR/counter_$counter.dat");};
  }
  $CONF{"COUNTER_$counter"}=join'||',map{"$_||$counter{$_}"} sort{lc($a) cmp lc($b)} keys %counter;
  &admin_param_saveconf;

  # valeur compteur
  {
    open (COUNTRW,"+<$DATA_DIR/counter_$counter.dat") || (&msg_fin("ERREUR !","Impossible de lire-�crire dans le fichier <b>$DATA_DIR/counter_$counter.dat</b> : $!<br> V�rifiez le CHMOD 666 de ce fichier."));
    eval{flock(COUNTRW,2);};
    my (undef,@lastips)=split(/\|/,<COUNTRW>);
    seek(COUNTRW,0,0);
    print COUNTRW (join '|',(int($form{'counter_value'}),@lastips));
    truncate(COUNTRW,tell(COUNTRW));
    close (COUNTRW);
  }
  
  &msg_fin("Configurer un Compteur",
           "<p align=\"center\">$FONT Enregistrement des caract�ristiques du compteur <b>$counter</b> effectu� !<br> </font></p>
            <center><form action=\"$CONF{'CGI_URL'}\" method=\"POST\"><input type=\"hidden\" name=\"PASSWD\" value=\"$form{PASSWD}\"><input type=\"submit\" name=\"ORDadmin_menu\" value=\"Cliquez ici pour continuer\"></form></center>");
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_delcounter {

  my $counter=$form{'counter'};
  delete($CONF{"COUNTER_$counter"});
  &admin_param_saveconf;
  
  unlink("$DATA_DIR/counter_$counter.dat");

  
  &msg_fin("Compteur supprim�e",
           "<p align=\"center\">$FONT Le compteur <b>$counter</b> a �t� supprim�e avec succ�s ! <br> </font></p>
            <center><form action=\"$CONF{'CGI_URL'}\" method=\"POST\"><input type=\"hidden\" name=\"PASSWD\" value=\"$form{PASSWD}\"><input type=\"submit\" name=\"ORDadmin_menu\" value=\"Cliquez ici pour continuer\"></form></center>");
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
sub admin_htmlcode {
my ($counter)=@_;
my (%tmpl);

  $tmpl{'htmlcode'}=qq|<script language="Javascript" type="text/javascript" src="$CONF{'CGI0_URL'}?counter=$counter"></script>|;
  $tmpl{'htmlcode2'}=&formfield_encode($tmpl{'htmlcode'});

  &msg_fin("Code HTML & test",
           "<p align=\"center\"><font face=\"Arial\" size=\"3\"><b><u>Compteur :</u> &nbsp; $counter</b></font></p>
            <p>$FONT Voici le code HTML � ins�rer dans la (ou les) page(s) de votre site, � l'endroit o� vous
            souhaitez que le compteur apparaisse :</font></p>
            <form action=\"\" method=\"get\">
            <textarea name=\"htmlcode\" rows=\"2\" cols=\"70\" wrap=\"off\">$tmpl{htmlcode2}</textarea>
            </form>
            <p align=\"center\">$FONT<b>Test du compteur, tel qu'il s'affichera dans votre site:</b></font><br>
            &nbsp;<br>
            $tmpl{htmlcode}
            </p>
            <p>&nbsp;</p>
            <center><form action=\"$CONF{'CGI_URL'}\" method=\"POST\"><input type=\"hidden\" name=\"PASSWD\" value=\"$form{PASSWD}\"><input type=\"submit\" name=\"ORDadmin_menu\" value=\"Retour menu\"></form></center>");
  
}
################################################
#### ATTENTION, r�utilisation/recopie du    ####
#### code source interdite et ill�gale      ####
################################################
