#!/usr/bin/perl

package functions::hero;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hero);


sub hero
{
	my ($kernel,$chan,$params,$user_mask) = @_;
	$main::irc->yield(privmsg => '#lix',"user mask : $user_mask");
	$main::irc->yield(privmsg => '#lix',"chan : $chan");
	$main::irc->yield(privmsg => '#lix',"params : $params");

	help() if ($params eq "help");
}

sub help
{
	$main::irc->yield(privmsg =>'#lix',"this is the help");
}
1;