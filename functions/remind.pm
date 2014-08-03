#!/usr/bin/perl

package functions::remind;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test);

use POE;

use Switch;

use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

my $dbhost = ('mysql.iiens.net');
my $socket = ('/var/run/mysql/mysql.sock');


sub load_reminds
{
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	
	my $sth = $dbh->prepare('SELECT * FROM lix_reminds WHERE time > ?');
	my $rv = $sth->execute(time()) or die "Can not execute the query: $sth->errstr\n";
	my $ref;
	if ($rv > 0)
	{
		while ( $ref = $sth->fetchrow_hashref() ) 
		{
		    if ( $$ref{'time'} > time() ) 
		    {
		    	my $converted_time = $$ref{'time'} - time();
		    	$main::irc->delay([privmsg => $$ref{'author'},$$ref{'remind'}],$converted_time);
		    }
		}
	}
	clean_remind();
	return;
}

sub remind
{
	my ($kernel,$chan,$msg,$user) = @_;
	#my ($param) =($msg =~ /^!remind\s+(.*?)\s*$/);
	my @message = split(' in ',$msg);

	if (length($msg) > 4)
	{
		switch($msg)
		{
			case "see"
			{
				$main::irc->yield(privmsg => '#lix',"message see ");
			}
			case "del"
			{
				$main::irc->yield(privmsg => '#lix',"message del ");
			}
			else
			{
				my @message = split(' in ',$msg);
				my $msg_to_remind = $message[0];
				my $time_to_remind = $message[1];

				my $converted_time = 0;

				if ($time_to_remind =~ /days/) 
				{
					my @split1 = split('days',$time_to_remind);
					my $number_days = $split1[0];
					$number_days =~ s/^\s+//;
					$number_days =~ s/\s+$//;
					$converted_time = $converted_time + 24 * 3600 * $number_days;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /day/) 
				{
					my @split1 = split('day',$time_to_remind);
					my $number_days = $split1[0];
					$number_days =~ s/^\s+//;
					$number_days =~ s/\s+$//;
					$converted_time = $converted_time + 24 * 3600 * $number_days;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /hours/) 
				{
					my @split1 = split('hours',$time_to_remind);
					my $number_hours = $split1[0];
					$number_hours =~ s/^\s+//;
					$number_hours =~ s/\s+$//;
					$converted_time = $converted_time + 3600 * $number_hours;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /hour/) 
				{
					my @split1 = split('hour',$time_to_remind);
					my $number_hours = $split1[0];
					$number_hours =~ s/^\s+//;
					$number_hours =~ s/\s+$//;
					$converted_time = $converted_time + 3600 * $number_hours;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /minutes/) 
				{
					my @split1 = split('minutes',$time_to_remind);
					my $number_minutes = $split1[0];
					$number_minutes =~ s/^\s+//;
					$number_minutes =~ s/\s+$//;
					$converted_time = $converted_time + 60 * $number_minutes;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /minute/) 
				{
					my @split1 = split('minute',$time_to_remind);
					my $number_minutes = $split1[0];
					$number_minutes =~ s/^\s+//;
					$number_minutes =~ s/\s+$//;
					$converted_time = $converted_time + 60 * $number_minutes;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /seconds/) 
				{
					my @split1 = split('seconds',$time_to_remind);
					my $number_seconds = $split1[0];
					$number_seconds =~ s/^\s+//;
					$number_seconds =~ s/\s+$//;
					$converted_time = $converted_time + $number_seconds;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				if ($time_to_remind =~ /second/) 
				{
					my @split1 = split('seconds',$time_to_remind);
					my $number_seconds = $split1[0];
					$number_seconds =~ s/^\s+//;
					$number_seconds =~ s/\s+$//;
					$converted_time = $converted_time + $number_seconds;
					$time_to_remind = $split1[1];
					$time_to_remind =~ s/^\s+//;
				}
				my $remindTime = $converted_time + time();
				
				my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");

				my $sth1 = $dbh->prepare("SELECT MAX(`id`) FROM `lix_reminds`")
					or die "Can not prepare";
				my $rv1 = $sth1->execute()
					or die "Can not execute the query";

				my $index = 0;
				if ($rv1 >= 1)
				{
					
					my $row = $sth1->fetchrow_hashref();
					$index = $$row{'MAX(`id`)'};
				}

				my $sth = $dbh->prepare('INSERT INTO lix_reminds (id, author, remind, time) VALUES (?, ?, ?, ?)');
				my $rv = $sth->execute($index + 1,$user,$msg_to_remind,$remindTime) or die "Can not execute the query: $sth->errstr\n";
				if ($rv >= 1)
				{
					$main::irc->yield(privmsg => $chan,"Remind added !");
					$main::irc->delay([privmsg => $user,$msg_to_remind],$converted_time);

				}
				else
				{
					$main::irc->yield(privmsg => $chan,"There was an error when trying to create a remind");
				}
			}
		}
	}
}

sub clean_remind
{
	my ($kernel,$user_info,$msg) = @_[KERNEL, ARG0, ARG2];
	my $dbh = DBI->connect("DBI:mysql:$database:$dbhost;mysql_socket=$socket","$db_username","$password_bdd");
	my $sth = $dbh->prepare('DELETE FROM lix_reminds WHERE time < ?');
	my $rv = $sth->execute(time()) or die "Can not execute the query: $sth->errstr\n";
	if ($rv >= 1)
	{
		$main::irc->yield(privmsg => '#lix',"Cleaned all old reminds !");
	}
	else
	{
		$main::irc->yield(privmsg => '#lix',"No reminds have been deleted");
	}

}


1;
