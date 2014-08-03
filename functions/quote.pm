#!/usr/bin/perl

package functions::quote;

use strict;
use warnings;

use DBD::mysql;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(addquote delquote getquote whoquote whenquote topicquote);


my $nick;
my $color_chan=4;

use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

my $dbhost = ('mysql.iiens.net');
my $socket = ('/var/run/mysql/mysql.sock');




 # Ajout d'une quote
sub addquote
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");

	my ($kernel,$chan,$param,$user) = @_;
	my ($quote) = $param;
	if ($quote =~ m/Michou/)
	{
		$main::irc->yield(privmsg => $chan,"J'ai autre chose à faire que m'intéresser à Michou !");
	}
	else
	{
		# On récupère la date
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year=1900+$year;
		my $date =  $year."-".($mon+1)."-".$mday." ".$hour.":".$min.":".$sec;

		my $nb_quote;

		if (length($quote) > 2)
		{
			my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_quotes` WHERE chan = ?;")
				or die "Can not prepare";
			my $rv = $sth->execute($chan)
				or die "Can not execute the query";
			if ($rv >= 1)
			{
				my $numrows;
				if (my $ref = $sth->fetchrow_hashref())
				{
						 $nb_quote= $ref->{'numrows'};
				}
			}
			$nb_quote= $nb_quote + 1;
		$sth->finish;
			my $sth2 = $dbh->prepare('INSERT INTO lix_quotes (author, quote, qdate, chan, id_chan) VALUES (?, ?, ?, ?, ?)');

			my $rv2 = $sth2->execute($user, $quote,$date,$chan,$nb_quote) or die "Can not execute the query: $sth->errstr\n";
			if ($rv2 >= 1)
			{
				my $sth2 = $dbh->prepare("SELECT count(*) as numrows FROM `lix_quotes` WHERE chan = ?;")
					or die "Can not prepare";
				my $rv2 = $sth2->execute($chan)
					or die "Can not execute the query";
				if ($rv >= 1)
				{
					my $numrows;
					if (my $ref = $sth2->fetchrow_hashref())
					{
							my $id_quote= $ref->{'numrows'};
							$main::irc->yield(privmsg => $chan,"Ajout de la quote $id_quote sur $chan");
					}
				}
			}
			else
			{
				my $server->command ( "notice $nick Unable to add the quote.\n" );
			}
			$sth2->finish;
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Une quote doit faire plus de deux caractères !\n" );
		}
	}
}

#Suppression d'une quote
sub delquote
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my ($kernel,$chan,$param) = @_;
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("UPDATE `lix_quotes` SET  `visible` =  '1' WHERE  `lix_quotes`.`chan` =?  AND `lix_quotes`.`id_chan`=?  LIMIT 1 ;")
		or die "Can not prepare";
		my $rv = $sth->execute($chan,$param)
		or die "Can not execute the query";
		if ($rv >= 1)
		{
			$main::irc->yield(privmsg => $chan,"Quote $param supprimée");
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Erreur lors de la suppression de la quote $param");
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"Merci de spécifier un numéro de quote à supprimer");
	}
}


# Affichage d'une quote
sub getquote
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE visible = 0 AND chan = ? AND id_chan = ?;")
		or die "Can not prepare ";
		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $quote_t = $sth->fetchrow_hashref();
			my $quote = $quote_t->{'quote'};
			my $chan = $quote_t->{'chan'};
			my $id_chan = $quote_t->{'id_chan'};
			 # my $quote=no_hl($quote);
			 # $quote =~ s/./\x0f$&/g;
			# my $quote=no_format($quote);
			my $message =( "\x03".$color_chan." [".$chan.":".$id_chan."]"." \x03".""." $quote");
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Quote not found !");
		}
		$sth->finish;
	}
	else
	{ #Si il n'y a pas que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE quote REGEXP ? AND visible = 0 AND chan = ? order by rand() limit 1;")
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
			my $quote_t = $sth->fetchrow_hashref();
			my $quote = $quote_t->{'quote'};
			my $chan = $quote_t->{'chan'};
			my $id_chan = $quote_t->{'id_chan'};
			# my $quote=no_hl($quote);
			# $quote =~ s/./\x0f$&/g;
			# my $quote=no_format($quote);
			my $message =( "\x03".$color_chan." [".$chan.":".$id_chan."]"." \x03".""." $quote");
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Quote not found !");
		}
		$sth->finish;
	}
	return;
}


sub countquote
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my ($kernel,$chan,$msg) = @_;
	#my ($param) =($msg =~ /^!countquote\s+(.*?)\s*$/);
	
	my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE quote REGEXP ? AND visible = 0 AND chan = ? order by rand();")
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
		my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_quotes` WHERE chan = ?;")
		or die "Can not prepare";
		my $rv = $sth->execute($chan)
			or die "Can not execute the query";
		if ($rv >= 1)
		{
			my $numrows;
			if (my $ref = $sth->fetchrow_hashref())
			{
					my $nb_quote= $ref->{'numrows'};
					$main::irc->yield(privmsg => $chan,"There are $nb_quote quote(s) in the database");
			}
		}
		$sth->finish;
	}
	else
	{
		my $rv = $sth->execute($string,$chan) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $number_of_quotes = 0;
			while (my $number = $sth -> fetchrow_hashref() )
			{
				$number_of_quotes = $number_of_quotes + 1;
			}
			my $message =( "\x03".$color_chan." [".$chan."]"." \x03".""." ".$number_of_quotes." quote(s) matching ".$string);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"\x03".$color_chan." [".$chan."]"." \x03".""." 0 quote matching ".$string);
		}
		$sth->finish;
	}
return;
}

 # Affichage de qui a quote
sub whoquote
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE visible = 0 AND chan= ? AND id_chan = ?;")
		or die "Can not prepare ";

		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $quote_t = $sth->fetchrow_hashref();
			my $qdate = $quote_t->{'qdate'};
			my $author = $quote_t->{'author'};
			my $message =( "Quote added by ".$author);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			my $message =( "Quote not found!");
			$main::irc->yield(privmsg => $chan,$message);
		}
		$sth->finish;
	}
	else
	{
		my $message =("Usage : !whoquote <id>");
		$main::irc->yield(privmsg => $chan,$message);
	}
	return;
}

sub whenquote
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE visible = 0 AND chan= ? AND id_chan = ?;")
		or die "Can not prepare ";

		my $rv = $sth->execute($chan,$param) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $quote_t = $sth->fetchrow_hashref();
			my $qdate = $quote_t->{'qdate'};
			my $author = $quote_t->{'author'};
			my $message =( "Quote added the ".$qdate);
			$main::irc->yield(privmsg => $chan,$message);
		}
		else
		{
			my $message =( "Quote not found!");
			$main::irc->yield(privmsg => $chan,$message);
		}
		$sth->finish;
	}
	else
	{
		my $message =("Usage : !whoquote <id>");
		$main::irc->yield(privmsg => $chan,$message);
	}
	return;
}

# sub db
# {
# 	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
# 	my ($kernel,$chan) = @_;
# 	my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_quotes` WHERE chan = ?;")
# 		or die "Can not prepare";
# 	my $rv = $sth->execute($chan)
# 		or die "Can not execute the query";
# 	if ($rv >= 1)
# 	{
# 		my $numrows;
# 		if (my $ref = $sth->fetchrow_hashref())
# 		{
# 				my $nb_quote= $ref->{'numrows'};
# 				$main::irc->yield(privmsg => $chan,"Nombre de quotes dans la base de données: $nb_quote");
# 		}
# 	}
# 	$sth->finish;
# }

sub  topicquote
{
	my ($kernel,$chan,$msg,$user) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");

	my $is_op = 0;
	my $is_voice = 0;
	$is_op = $main::irc->is_channel_operator($chan,$user);
	$is_voice = $main::irc->has_channel_voice($chan,$user);

	if (($is_op == 1)or($is_voice == 1))
	{

		my $sth = $dbh->prepare("SELECT * FROM `lix_quotes` WHERE visible = 0 AND chan = ? order by rand() limit 1;;")
		or die "Can not prepare ";

		my $rv = $sth->execute($chan) or die "Can not execute ";

		if ($rv >= 1)
		{
			my $quote_t = $sth->fetchrow_hashref();
			my $quote = $quote_t->{'quote'};
			$main::irc->yield(topic => $chan,$quote);;
		}
		else
		{
			$main::irc->yield($chan,"Error when trying to change the topic");
			# erreur
		}
		$sth->finish;
	}
	return;
}


1;
