#!/usr/bin/perl

package functions::help;

use strict;
use warnings;
use Switch;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(help);

sub help
{
	my ($kernel,$chan,$params,$user) = @_;
	#$main::irc->yield(privmsg => '#lix', "chan : ".$chan." user : ".$user);
	switch ($params)
	{
		case ""	{ $main::irc->yield(privmsg => $chan, "Help is available for the following topics : quote, votekick, rss, remind, help, admin commands"); }
		case "help" { $main::irc->yield(privmsg => $chan, "Display this message."); }
		# Quote commands
		case "quote" { $main::irc->yield(privmsg => $chan, "Commands available : addquote, delquote, countquote, getquote, topicquote, whoquote, whenquote."); }
		case "addquote" { $main::irc->yield(privmsg => $chan, "Add a quote in the database. Usage : !addquote <text>"); }
		case "delquote" { $main::irc->yield(privmsg => $chan, "Delete a quote from the database. Usage : !delquote <quote id>"); }
		case "countquote" { $main::irc->yield(privmsg => $chan, "Count the number of quote matching the parameter. If no parameter is specified, the number of quotes in the database is returned. Usageelete a quote from the database. Usage : !countquote <text>"); }
		case "getquote" { $main::irc->yield(privmsg => $chan, "Get a quote from the database. If no paramter is given, a random quote is picked. Usage : !getquote <text> or !getquote <quote id>"); }
		case "whoquote" { $main::irc->yield(privmsg => $chan, "Return the name of the user who added the quote. Usage : !whoquote <quote id>"); }
		case "whenquote" { $main::irc->yield(privmsg => $chan, "Return the date at which the quote has been added. Usage : !whenquote <quote id>"); }
		case "topicquote" { $main::irc->yield(privmsg => $chan, "Change the topic to a random quote. Usage : !topicquote"); }


		# Default case
		else { $main::irc->yield(privmsg => $chan, "Unknown command."); }

	}

}

1;

