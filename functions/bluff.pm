#!/usr/bin/perl

package functions::bluff;

use strict;
use warnings;

use DBD::mysql;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(addbluff delbluff getbluff whobluff whenbluff);


my $nick;
my $color_chan=4;

use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

my $dbhost = ('mysql.iiens.net');
my $socket = ('/var/run/mysql/mysql.sock');




 # Ajout d'une bluff
sub addbluff
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");

	my ($kernel,$chan,$param,$user) = @_;
	my ($bluff) = $param;
	if ($bluff =~ m/Michou/)
	{
		$main::irc->yield(privmsg => $chan,"J'ai autre chose à faire que m'intéresser à Michou !");
	}
	else
	{
		# On récupère la date
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year=1900+$year;
		my $date =  $year."-".($mon+1)."-".$mday." ".$hour.":".$min.":".$sec;

		my $nb_bluff;

		if (length($bluff) > 2)
		{
			my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_bluffs` WHERE chan = ?;")
				or die "Can not prepare";
			my $rv = $sth->execute($chan)
				or die "Can not execute the query";
			if ($rv >= 1)
			{
				my $numrows;
				if (my $ref = $sth->fetchrow_hashref())
				{
						 $nb_bluff= $ref->{'numrows'};
				}
			}
			$nb_bluff= $nb_bluff + 1;
		$sth->finish;
			my $sth2 = $dbh->prepare('INSERT INTO lix_bluffs (author, bluff, qdate, chan, id_chan) VALUES (?, ?, ?, ?, ?)');

			my $rv2 = $sth2->execute($user, $bluff,$date,$chan,$nb_bluff) or die "Can not execute the query: $sth->errstr\n";
			if ($rv2 >= 1)
			{
				my $sth2 = $dbh->prepare("SELECT count(*) as numrows FROM `lix_bluffs` WHERE chan = ?;")
					or die "Can not prepare";
				my $rv2 = $sth2->execute($chan)
					or die "Can not execute the query";
				if ($rv >= 1)
				{
					my $numrows;
					if (my $ref = $sth2->fetchrow_hashref())
					{
							my $id_bluff= $ref->{'numrows'};
							$main::irc->yield(privmsg => $chan,"Ajout de la bluff $id_bluff sur $chan");
					}
				}
			}
			else
			{
				my $server->command ( "notice $nick Unable to add the bluff.\n" );
			}
			$sth2->finish;
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Une bluff doit faire plus de deux caractères !\n" );
		}
	}
}

#Suppression d'une bluff
sub delbluff
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my ($kernel,$chan,$param) = @_;
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("UPDATE `lix_bluffs` SET  `visible` =  '1' WHERE  `lix_bluffs`.`chan` =?  AND `lix_bluffs`.`id_chan`=?  LIMIT 1 ;")
		or die "Can not prepare";
		my $rv = $sth->execute($chan,$param)
		or die "Can not execute the query";
		if ($rv >= 1)
		{
			$main::irc->yield(privmsg => $chan,"bluff $param supprimée");
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Erreur lors de la suppression de la bluff $param");
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"Merci de spécifier un numéro de bluff à supprimer");
	}
}


# Affichage d'une bluff
sub getbluff
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_bluffs` WHERE visible = 0 AND chan = ? AND id_chan = ?;")
		or die "Can not prepare ";
		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $bluff_t = $sth->fetchrow_hashref();
			my $bluff = $bluff_t->{'bluff'};
			my $chan = $bluff_t->{'chan'};
			my $id_chan = $bluff_t->{'id_chan'};
			 # my $bluff=no_hl($bluff);
			 # $bluff =~ s/./\x0f$&/g;
			# my $bluff=no_format($bluff);
			my $message =( "\x03".$color_chan." [".$chan.":".$id_chan."]"." \x03".""." $bluff");
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"bluff not found !");
		}
		$sth->finish;
	}
	else
	{ #Si il n'y a pas que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_bluffs` WHERE bluff REGEXP ? AND visible = 0 AND chan = ? order by rand() limit 1;")
		or die "Can not prepare ";
		# Pour faire une recherche SQL avec le paramètre LIKE il faut utiliser $string = %".$param."%";
		# Pour faire une recherche SQL avec le paramètre REGEXP, il faut utiliser le paramètre $string=$param directement. Le point seul '.' permet de faire une recherche aléatoire.
		my $string=$param; 
		$string =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;
		#	$string =~ s/\\s+$//;
		$string =~ s/^\s+//;
		$string =~ s/\s+$//;
		if (eval { qr($string)} ) { print "toto"; } else { $string =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;}
		if ($string =~ /^$/)
		{
		$string='.';
		}
		my $rv = $sth->execute($string,$chan) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $bluff_t = $sth->fetchrow_hashref();
			my $bluff = $bluff_t->{'bluff'};
			my $chan = $bluff_t->{'chan'};
			my $id_chan = $bluff_t->{'id_chan'};
			# my $bluff=no_hl($bluff);
			# $bluff =~ s/./\x0f$&/g;
			# my $bluff=no_format($bluff);
			my $message =( "\x03".$color_chan." [".$chan.":".$id_chan."]"." \x03".""." $bluff");
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"bluff not found !");
		}
		$sth->finish;
	}
	return;
}


sub countbluff
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my ($kernel,$chan,$msg) = @_;
	#my ($param) =($msg =~ /^!countbluff\s+(.*?)\s*$/);
	
	my $sth = $dbh->prepare("SELECT * FROM `lix_bluffs` WHERE bluff REGEXP ? AND visible = 0 AND chan = ? order by rand();")
	or die "Can not prepare ";
	# Pour faire une recherche SQL avec le paramètre LIKE il faut utiliser $string = %".$param."%";
	# Pour faire une recherche SQL avec le paramètre REGEXP, il faut utiliser le paramètre $string=$param directement. Le point seul '.' permet de faire une recherche aléatoire.
	my $string=$msg;
	$string =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	#$main::irc->yield(privmsg => $chan, "toto : $string");
	if ( $string eq "")
	{
		my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_bluffs` WHERE chan = ?;")
		or die "Can not prepare";
		my $rv = $sth->execute($chan)
			or die "Can not execute the query";
		if ($rv >= 1)
		{
			my $numrows;
			if (my $ref = $sth->fetchrow_hashref())
			{
					my $nb_bluff= $ref->{'numrows'};
					$main::irc->yield(privmsg => $chan,"There are $nb_bluff bluff(s) in the database");
			}
		}
		$sth->finish;
	}
	else
	{
		my $rv = $sth->execute($string,$chan) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $number_of_bluffs = 0;
			while (my $number = $sth -> fetchrow_hashref() )
			{
				$number_of_bluffs = $number_of_bluffs + 1;
			}
			my $message =( "\x03".$color_chan." [".$chan."]"." \x03".""." ".$number_of_bluffs." bluff(s) matching ".$string);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"\x03".$color_chan." [".$chan."]"." \x03".""." 0 bluff matching ".$string);
		}
		$sth->finish;
	}
return;
}

 # Affichage de qui a bluff
sub whobluff
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_bluffs` WHERE visible = 0 AND chan= ? AND id_chan = ?;")
		or die "Can not prepare ";

		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $bluff_t = $sth->fetchrow_hashref();
			my $qdate = $bluff_t->{'qdate'};
			my $author = $bluff_t->{'author'};
			my $message =( "bluff added by ".$author);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			my $message =( "bluff not found!");
			$main::irc->yield(privmsg => $chan,$message);
		}
		$sth->finish;
	}
	else
	{
		my $message =("Usage : !whobluff <id>");
		$main::irc->yield(privmsg => $chan,$message);
	}
	return;
}

sub whenbluff
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_bluffs` WHERE visible = 0 AND chan= ? AND id_chan = ?;")
		or die "Can not prepare ";

		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $bluff_t = $sth->fetchrow_hashref();
			my $qdate = $bluff_t->{'qdate'};
			my $author = $bluff_t->{'author'};
			my $message =( "bluff added the ".$qdate);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			my $message =( "bluff not found!");
			$main::irc->yield(privmsg => $chan,$message);
		}
		$sth->finish;
	}
	else
	{
		my $message =("Usage : !whobluff <id>");
		$main::irc->yield(privmsg => $chan,$message);
	}
	return;
}

# sub db
# {
# 	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
# 	my ($kernel,$chan) = @_;
# 	my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_bluffs` WHERE chan = ?;")
# 		or die "Can not prepare";
# 	my $rv = $sth->execute($chan)
# 		or die "Can not execute the query";
# 	if ($rv >= 1)
# 	{
# 		my $numrows;
# 		if (my $ref = $sth->fetchrow_hashref())
# 		{
# 				my $nb_bluff= $ref->{'numrows'};
# 				$main::irc->yield(privmsg => $chan,"Nombre de bluffs dans la base de données: $nb_bluff");
# 		}
# 	}
# 	$sth->finish;
# }

1;
