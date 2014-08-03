#!/usr/bin/perl

package functions::todo;

use strict;
use warnings;

use DBD::mysql;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(addtodo todo deltodo);


my $nick;
my $color_chan=8;

use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

my $dbhost = ('mysql.iiens.net');
my $socket = ('/var/run/mysql/mysql.sock');




 # Ajout d'une quote
sub addtodo
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
			my $sth = $dbh->prepare("SELECT count(*) as numrows FROM `lix_todo` WHERE chan = ?;")
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
			my $sth2 = $dbh->prepare('INSERT INTO lix_todo (author, quote, qdate, chan, id_chan) VALUES (?, ?, ?, ?, ?)');

			my $rv2 = $sth2->execute($user, $quote,$date,$chan,$nb_quote) or die "Can not execute the query: $sth->errstr\n";
			if ($rv2 >= 1)
			{
				my $sth2 = $dbh->prepare("SELECT count(*) as numrows FROM `lix_todo` WHERE chan = ?;")
					or die "Can not prepare";
				my $rv2 = $sth2->execute($chan)
					or die "Can not execute the query";
				if ($rv >= 1)
				{
					my $numrows;
					if (my $ref = $sth2->fetchrow_hashref())
					{
							my $id_quote= $ref->{'numrows'};
							$main::irc->yield(privmsg => $chan,"Task $id_quote added on $chan");
					}
				}
			}
			else
			{
				my $server->command ( "notice $nick Unable to add the task.\n" );
			}
			$sth2->finish;
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"A task should be at least two characters long !\n" );
		}
	}
}

#Suppression d'une quote
sub deltodo
{
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my ($kernel,$chan,$param) = @_;
	if ($param =~ /^[0-9]+$/)
	{ # Si j'ai que des chiffres
		my $sth = $dbh->prepare("UPDATE `lix_todo` SET  `visible` =  '1' WHERE  `lix_todo`.`chan` =?  AND `lix_todo`.`id_chan`=?  LIMIT 1 ;")
		or die "Can not prepare";
		my $rv = $sth->execute($chan,$param)
		or die "Can not execute the query";
		if ($rv >= 1)
		{
			$main::irc->yield(privmsg => $chan,"Task $param deleted");
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Erreur when trying to delete task  $param");
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"Please give a task number to delete");
	}
}


# Affichage d'une quote
sub todo
{
	my ($kernel,$chan,$param) = @_;
	our $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	if ( length($param) == 0 )
	{
		my $sth = $dbh->prepare("SELECT * FROM `lix_todo` WHERE visible = 0 AND chan = ?")
		or die "Can not prepare ";
		my $rv = $sth->execute($chan) or die "Can not execute ";
		my $ref;
		if ($rv > 0)
		{
			while ( $ref = $sth->fetchrow_hashref() ) 
			{
				my $quote = $ref->{'quote'};
				my $chan = $ref->{'chan'};
				my $id_chan = $ref->{'id_chan'};
				my $message =( "\x03".$color_chan." [Task ".$id_chan."]"." \x03".""." $quote");
				$main::irc->yield(privmsg => $chan,$message);
			}

		}
		else
		{
			$main::irc->yield(privmsg => $chan,"No tasks on the todo !");
		}
		$sth->finish;
	}
	else
	{
		my $sth = $dbh->prepare("SELECT * FROM `lix_todo` WHERE quote REGEXP ? AND visible = 0 AND chan = ?")
		or die "Can not prepare ";
		# Pour faire une recherche SQL avec le paramètre LIKE il faut utiliser $string = %".$param."%";
		# Pour faire une recherche SQL avec le paramètre REGEXP, il faut utiliser le paramètre $string=$param directement. Le point seul '.' permet de faire une recherche aléatoire.
		my $string=$param; 
		$string =~ s/^\s+|\s+$//g;
		$string =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;		
		#$main::irc->yield(privmsg => $chan,"Param : ~".$string."~");
		if (eval { qr($string)} ) { print "toto"; } else { $string =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;}
		if ($string =~ /^$/)
		{
		$string='.';
		}
		my $rv = $sth->execute($string,$chan) or die "Can not execute ";
		if ($rv > 0)
		{
			my $ref;
			while ( $ref = $sth->fetchrow_hashref() ) 
			{
				my $quote = $ref->{'quote'};
				my $chan = $ref->{'chan'};
				my $id_chan = $ref->{'id_chan'};
				my $message =( "\x03".$color_chan." [Task ".$id_chan."]"." \x03".""." $quote");
				$main::irc->yield(privmsg => $chan,$message);
			}

		}
		else
		{
			$main::irc->yield(privmsg => $chan,"No tasks on the todo !");
		}
		$sth->finish;
	}
	return;
}


1;