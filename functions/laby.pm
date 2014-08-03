#!/usr/bin/perl

package functions::laby;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(laby);

sub laby
{
	my ($kernel,$chan) = @_;
	my $msg = "Laby is my creator";
	$main::irc->yield(privmsg => $chan,$msg);
	return;
	
}

1;
