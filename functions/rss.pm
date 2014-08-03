
package functions::rss;

use strict;
use warnings;

use DBD::mysql;
use Switch;
use POE qw(Component::IRC::State);

# Module RSS
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;

use Data::Dumper;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(rss rss_refresh rss_add rss_del rss_see);


use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

#my $dbhost = ('mysql.iiens.net');
my $dbhost = ('193.54.225.85');
my $socket = ('/var/run/mysql/mysql.sock');

#Variables pour le module RSS
my $color_rss_url = 3;
my $color_rss_chan = 12;
my $time_check_rss_default = 60;
my %first_rss_titles;
my $number_saved_titles = 10;
my $empty_string = "NoTitle";
my $firstrun = 1;

sub rss_refresh
{
	my $kernel = $_[0];
	
	%first_rss_titles = ();
	my $current_channels = $main::irc->channels();
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
		or die "Could not connect to database during the execution of rss_refresh. Error : " . DBI->errstr;


	if (defined $current_channels )
	{
	 	
	 	for my $chan ( keys %{ $current_channels } )
	 	{

			
			my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE chan = ?")
				or die "Can not prepare ";
			my $rv = $sth->execute($chan)
				or die "Can not execute ";
			
			if ($rv >= 1)
			{
				while ( my $ref = $sth->fetchrow_hashref() ) 
				{
					my $url = $ref->{'url'};
					my $id = $ref->{'id'};
					my $rss = get($url);
					my $rss_content = XMLin($rss);
					if ( ref($rss_content->{channel}->{item}) eq 'ARRAY' )
					{
						# There is more than one element in the RSS flux
						my $i = 0;

						while ( $i < $number_saved_titles )
						{
							if ( defined $rss_content->{channel}->{item}->[$i]->{title} )
							{
								#$first_rss_titles{ $id }{ "$i" } = $rss_content->{channel}->{item}->[$i]->{title};
								my $title = $rss_content->{channel}->{item}->[$i]->{title};
								$title =~ s/"//g;
								push(@{$first_rss_titles{ $id }},$title);
							}
							else
							{
								#$first_rss_titles{ $id }{ "$i" } = $empty_string ;
								push(@{$first_rss_titles{ $id }},$empty_string);
							}
							$i = $i + 1;
						}
					}
					else
					{
						# There is only one element in the RSS flux
						my $i = 0;
						my $title = $rss_content->{channel}->{item}->[$i]->{title};
						$title =~ s/"//g;
						push(@{$first_rss_titles{ $id }},$title);
						$i++;
						while ( $i < $number_saved_titles )
						{
							push(@{$first_rss_titles{ $id }},$empty_string);
							$i++;
						}
					}
				}
				$main::irc->yield(privmsg => "#lix","Refreshed RSS flux for chan $chan");
			}
			$sth->finish;
		}
	}
	#$kernel->delay_set("_rss_update", 10,($kernel));
	open (MYFILE, '>>data.txt');
	print MYFILE Dumper(%first_rss_titles);
	close (MYFILE);
	$dbh->disconnect;
	return;
}


sub rss_update
{
	# kernel is the 3rd thing in the argument list when we call with delay_set
	my $kernel = $_[2];
	if ($firstrun == 1)
	{
		rss_refresh($kernel);
		$firstrun = 0;
		return;
	}
	else 
	{
	my $dbh;
      until (
          $dbh = DBI->connect( "DBI:mysql:$database:$dbhost;mysql_socket=$socket", "$db_username", "$password_bdd" )
      ) {
          warn "Can't connect: $DBI::errstr. Pausing before retrying.\n";
          sleep( 5 );
      }

	#my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
	#	or die "Could not connect to database during the execution of rss_update. Error : " . DBI->errstr;

	my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE active = 1;")
		or die "Can not prepare ";
	my $rv = $sth->execute()
		or die "Can not execute ";
	if ($rv >= 1)
	{
		while ( my $ref = $sth->fetchrow_hashref() ) 
		{
			my $url = $ref->{'url'};
			my $id = $ref->{'id'};
			my $id_chan = $ref->{'id_chan'};
			my $chan = $ref->{'chan'};
			my $time_check_rss  = $ref->{'check_interval'};
			my $title_flux = $ref->{'title'};
			my $last_check = $ref->{'lastcheck'};
			my $timestamp = time();
			my $nextcheck = $last_check + $time_check_rss;
			if ( $timestamp > $nextcheck )
			{
				if ( defined $first_rss_titles{$id} )
				{
					my $rss = get($url);
					my $rss_content = XMLin($rss);
					my $spl = 0;
					my @last_titles = [];
					if ( ref($rss_content->{channel}->{item}) eq 'ARRAY' )
					{
						$spl = scalar(@{$rss_content->{channel}->{item}});
						@last_titles = @{$first_rss_titles{$id}};
					}
					else
					{
						if (defined $rss_content->{channel}->{item}->{title})
						{
							$spl = 1;
							my $title = $rss_content->{channel}->{item}->{title};
							$title =~ s/"//g;
							@last_titles=push(@last_titles,$title);
						}

					}
					

					# je parcours tous les titres du flux rss, je regarde s'ils sont dans le hash du hash, jusqu'à ce que le titre considéré est le dernier titre du hash qui n'est pas un NoTitle

					# We get the array with the last $number_saved_titles
					
					while ( @last_titles[scalar(@last_titles) - 1]  eq $empty_string )
					{
						pop(@last_titles);

					}

					my $i = 0;
					#$main::irc->yield(privmsg => $chan,"title I : $rss_content->{channel}->{item}->[$i]->{title}");
					if ( $spl > 1 )
					{
						if ( $spl > $number_saved_titles )
						{
							$spl = $number_saved_titles;
						}
						my $title = $rss_content->{channel}->{item}->[$i]->{title};
						$title =~ s/"//g;
						while ( ( $i < $spl )&&( $title ne @last_titles[scalar(@last_titles)]))
						{
							$i++;
						}

						$i = $i - 1;
						my @save_last_titles = @last_titles;
						for( my $j = $i ; $j > -1 ; $j-- )
						{
							
							#$main::irc->yield(privmsg => $chan,"title \$j = $j : $rss_content->{channel}->{item}->[$j]->{title}");
							my $title = $rss_content->{channel}->{item}->[$j]->{title};
							$title =~ s/"//g;
							if ( !grep( /^\b$title$/i, @save_last_titles ) )
							{
								$main::irc->yield(privmsg => $chan,"\x03".$color_rss_chan."[$title_flux]\x03".$color_rss_url." $title \x03 ($rss_content->{channel}->{item}->[$j]->{link})");
								unshift(@last_titles,$title);
							}
						}
						while ( scalar(@last_titles) < $number_saved_titles )
						{
							push(@last_titles,$empty_string);
						}

						my $sth2 = $dbh->prepare("UPDATE `lix_rss` SET `lastcheck` = ? WHERE `lix_rss`.`id` = ? ;")
							or die "Can not prepare ";

						my $rv2 = $sth2->execute(time(),$id)
							or die "Can not execute ";
						if ($rv2 == 0)
						{
							$main::irc->yield(privmsg => $chan,"Error updating the last check timestamp");
						}
						$sth2->finish;

						@{$first_rss_titles{ $id }} = @last_titles;
					}
				}
				else
				{
					#rss_refresh($kernel);
				}
			}
			else
			{
				#$main::irc->yield(privmsg => $chan,"The delay between two checks is not over yet");
			}
		
		}
	}
	$sth->finish;
	$dbh->disconnect;
	$kernel->delay_set('_rss_update',60);
	return;
}
}

sub rss
{
	my ($kernel,$chan,$msg,$usr)= @_;
	my @msg_content= split(' ',$msg);
	my ($command, $tail) = split /\s/, $msg, 2;
	switch($command)
	{
		case "add"
		{
			rss_add($kernel,$chan,$tail,$usr);
		}
		case "edit"
		{
			rss_edit($kernel,$chan,$tail,$usr);
		}
		case "del"
		{
			rss_del($kernel,$chan,$tail,$usr);
		}
		case "see"
		{
			rss_see($kernel,$chan,$tail,$usr);
		}
		case "refresh"
		{
			rss_refresh($chan,$chan,$kernel);
		}
		case "update"
		{
			rss_update($chan,$chan,$kernel);
		}
		else
		{
			$main::irc->yield(privmsg =>$chan,"Allowed actions are : add, edit, del, see.");
		}
	}
}

sub rss_edit
{
	my ($kernel,$chan,$msg,$usr)= @_;
	my @msg_content= split(' ',$msg);
	my ($id_chan, $tail) = split /\s/, $msg, 2;
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
		or die "Could not connect to database during the execution of rss_edit. Error : " . DBI->errstr;
	if ($id_chan =~ /^[0-9]+$/)
	{
		my ($to_edit, $value) = split /\s/, $tail, 2;
		#$main::irc->yield(privmsg => $chan,"to edit : $to_edit");
		#$main::irc->yield(privmsg => $chan,"content : $value");
		switch($to_edit)
		{
			case "title"
			{

				my $sth = $dbh->prepare("UPDATE `lix_rss` SET `title` = ? WHERE `lix_rss`.`id_chan` = ? AND `lix_rss`.`chan` = ?;")
					or die "Can not prepare ";

				my $rv = $sth->execute($value,$id_chan,$chan)
					or die "Can not execute ";
				if ($rv >= 1)
				{
					$main::irc->yield(privmsg => $chan,"RSS feed updated with the new title : $value");
				}
				else
				{
					$main::irc->yield(privmsg => $chan,"Failed to update the RSS $id_chan with a new title");
				}
			}
			case "url"
			{
				$value =~ s/https/http/;
				my $sth = $dbh->prepare("UPDATE `lix_rss` SET `url` = ? WHERE `lix_rss`.`id_chan` = ? AND `lix_rss`.`chan` = ?;")
					or die "Can not prepare ";

				my $rv = $sth->execute($value,$id_chan,$chan)
					or die "Can not execute ";
				if ($rv >= 1)
				{
					$main::irc->yield(privmsg => $chan,"RSS feed updated with the new url : $value");
				}
				else
				{
					$main::irc->yield(privmsg => $chan,"Failed to update the RSS $id_chan with a new url");
				}
			}
			case "interval"
			{
				if ($value =~ /^[0-9]+$/)
				{
					my $sth = $dbh->prepare("UPDATE `lix_rss` SET `check_interval` = ? WHERE `lix_rss`.`id_chan` = ? AND `lix_rss`.`chan` = ?;")
						or die "Can not prepare ";

					my $rv = $sth->execute($value,$id_chan,$chan)
						or die "Can not execute ";
					if ($rv >= 1)
					{
						$main::irc->yield(privmsg => $chan,"RSS feed updated with the new url : $value");
					}
					else
					{
						$main::irc->yield(privmsg => $chan,"Failed to update the RSS $id_chan with a new url");
					}
				}
				else
				{
					$main::irc->yield(privmsg => $chan,"The interval should be a number (in seconds)");
				}
			}
			else
			{
				$main::irc->yield(privmsg => $chan,"The options I can edit are : title, url, interval");
			}
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"No valid RSS ID given");
	}
	$dbh->disconnect;
	return;
}


sub rss_add
{
	my ($kernel,$chan,$msg,$usr)= @_;
	#$main::irc->yield(privmsg => $chan,"message : $msg");
	my @message = $msg;
	my $url_rss_feed = $message[0];
	$url_rss_feed =~ s/https/http/;
	my $rss = get($url_rss_feed);
	my $rss_content = XMLin($rss);
	my $title = $rss_content->{channel}->{title};
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
		or die "Could not connect to database during the execution of rss_add. Error : " . DBI->errstr;
	if ( length $rss)
	{
		# Default time for rss check
		my $time_check_rss = $time_check_rss_default;
		if ( defined $message[1] )
		{
			$time_check_rss = $message[1];
		}

		my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE url REGEXP ? AND chan = ?;")
		or die "Can not prepare ";
		my $rv = $sth->execute($url_rss_feed,$chan) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $sth2 = $dbh->prepare("SELECT * FROM `lix_rss` WHERE url REGEXP ? AND chan = ? AND active = 0;")
				or die "Can not prepare ";
			my $rv2 = $sth2->execute($url_rss_feed,$chan)
				or die "Can not execute ";
			if ($rv2 >= 1)
			{
				# Note : obligé de faire deux update pour mettre à jour deux trucs, je sais pas pourquoi. Peut etre utiliser une virgule au lieu du AND ?
				my $sth3 = $dbh->prepare("UPDATE `lix_rss` SET `active` = 1 WHERE `lix_rss`.`url` REGEXP ? AND `lix_rss`.`chan` = ?;")
					or die "Can not prepare ";
				my $rv3 = $sth3->execute($url_rss_feed,$chan)
					or die "Can not execute ";

				my $sth4 = $dbh->prepare("UPDATE `lix_rss` SET `check_interval` =  ? WHERE `lix_rss`.`url` REGEXP ? AND `lix_rss`.`chan` = ?;")
					or die "Can not prepare ";
				my $rv4 = $sth4->execute($time_check_rss,$url_rss_feed,$chan)
					or die "Can not execute ";
				if ($rv4 >= 1)
				{
					$main::irc->yield(privmsg => $chan,"RSS feed $url_rss_feed added on chan $chan ");
				}
			}
			else
			{
				$main::irc->yield(privmsg => $chan,"This RSS feed already exists for $chan !");
			}
		}
		else
		{
			my $nb_rss_feeds = 0;
			
			my $sth = $dbh->prepare("SELECT MAX(`id`) FROM `lix_rss`;")
				or die "Can not prepare";
			my $rv = $sth->execute()
				or die "Can not execute the query";
			if ($rv >= 1)
			{
				my $numrows;
				if (my $row = $sth->fetchrow_hashref())
				{
						 $nb_rss_feeds= $$row{'MAX(`id`)'};
				}
			}
			$nb_rss_feeds = $nb_rss_feeds + 1;
			$sth->finish;

			my $next_id_chan = 0;

			my $sth1 = $dbh->prepare("SELECT MAX(`id_chan`) FROM `lix_rss` WHERE `chan` = ?;")
				or die "Can not prepare";
			my $rv1 = $sth1->execute($chan)
				or die "Can not execute the query";
			if ($rv1 >= 1)
			{
				
				my $row = $sth1->fetchrow_hashref();
				$next_id_chan = $$row{'MAX(`id_chan`)'};
			}
			$next_id_chan = $next_id_chan + 1;
			$sth1->finish;


			my $sth2 = $dbh->prepare('INSERT INTO lix_rss (id, chan, id_chan, url, title, check_interval,lastcheck) VALUES (?, ?, ?, ?, ?, ?, ?)')
				or die "Can not prepare";
			my $rv2 = $sth2->execute($nb_rss_feeds, $chan, $next_id_chan, $url_rss_feed, $title, $time_check_rss,time())
				or die "Can not execute the query: $sth->errstr\n";
			if ($rv2 >= 1)
			{
				my $i = 0;
				while ( $i < $number_saved_titles )
				{
					if ( defined $rss_content->{channel}->{item}->[$i]->{title} )
					{
					#	$first_rss_titles{ $nb_rss_feeds }{ "$i" } = $rss_content->{channel}->{item}->[$i]->{title};
					}
					else
					{
					#	$first_rss_titles{ $nb_rss_feeds }{ "$i" } = "NoTitle" ;
					}
					$i = $i + 1;
				}
				$main::irc->yield(privmsg => $chan,"RSS feed $url_rss_feed added on chan $chan ");
			}
		}
		$sth->finish;
		if (!defined $title)
		{
			$main::irc->yield(privmsg => $chan, "This RSS feed doesn't have any title. You may want to edit it with !rss_edit");
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"This URL is empty. Nothing happened");
	}
	$dbh->disconnect;
	rss_refresh($kernel);
	return;
}


sub rss_del
{
	my ($kernel,$chan,$msg,$usr)= @_;
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
		or die "Could not connect to database during the execution of rss_del. Error : " . DBI->errstr;
	if ($msg =~ /^[0-9]+$/)
	{
		my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE id_chan = ? AND chan = ? AND active = 1;")
			or die "Can not prepare";
		my $rv = $sth->execute($msg,$chan)
			or die "Can not execute ";
		if ($rv >= 1)
		{
			my $sth = $dbh->prepare("UPDATE `lix_rss` SET `active` = 0 WHERE `lix_rss`.`id_chan` = ? AND `lix_rss`.`chan` = ?;")
			or die "Can not prepare ";
			my $rv2 = $sth->execute($msg,$chan) or die "Can not execute ";
			if ($rv2 >= 1)
			{
				$main::irc->yield(privmsg => $chan,"RSS feed $msg deleted on $chan !");
			}
			else
			{
				$main::irc->yield(privmsg => $chan,"Error why trying to delete RSS feed");
			}
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"There is no RSS feed on $chan with this ID !");
		}
		$sth->finish;
	}
	else
	{
		my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE url REGEXP ? AND chan = ? AND active = 1;")
		or die "Can not prepare ";
		my $rv = $sth->execute($msg,$chan) or die "Can not execute ";
		if ($rv >= 1)
		{
			my $sth = $dbh->prepare("UPDATE `lix_rss` SET `active` = 0 WHERE `lix_rss`.`url` REGEXP ? AND `lix_rss`.`chan` = ?;")
			or die "Can not prepare ";
			my $rv2 = $sth->execute($msg,$chan) or die "Can not execute ";
			if ($rv2 >= 1)
			{
				$main::irc->yield(privmsg => $chan,"RSS feed $msg deleted on $chan !");
			}
			else
			{
				$main::irc->yield(privmsg => $chan,"Error why trying to delete RSS feed");
			}
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"This RSS feed doesn't exist on $chan !");
		}
		$sth->finish;
	}
	$dbh->disconnect;
	return;
}


sub rss_see
{
	my ($kernel,$chan,$msg,$usr)= @_;
	my ($param) =($msg =~ /^!rss_see\s+(.*?)\s*$/);
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd")
		or die "Could not connect to database during the execution of rss_see. Error : " . DBI->errstr;

	my $sth = $dbh->prepare("SELECT * FROM `lix_rss` WHERE chan = ? AND active = 1;")
	or die "Can not prepare ";
	my $rv = $sth->execute($chan) or die "Can not execute ";
	if ($rv >= 1)
	{
		my $ref;
		my $url;
		my $id_chan;
		my $time_check_rss;
		my $title;
		while ( $ref = $sth->fetchrow_hashref() ) 
		{
			$url = $ref->{'url'};
			$id_chan = $ref->{'id_chan'};
			$time_check_rss  = $ref->{'check_interval'};
			$title = $ref->{'title'};
			#$main::irc->yield(privmsg => $chan,"url : $url");
			my $message =("\x03".$color_rss_chan."[".$chan.":".$id_chan."] \x03".$color_rss_url." $title\x03 (".$url.")"." every $time_check_rss seconds. Last check : $ref->{'lastcheck'}");
			$main::irc->yield(privmsg => $chan,$message);
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"There is no RSS feed on this chan !");
	}
	$sth->finish;

	$dbh->disconnect;
	return;
}

1;