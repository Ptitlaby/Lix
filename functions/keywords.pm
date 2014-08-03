#!/usr/bin/perl

package functions::keywords;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(laby gmab time amora twibby);

sub laby
{
	my ($kernel,$chan) = @_;
	my $msg = "Laby is my creator";
	$main::irc->yield(privmsg => $chan,$msg);
	return;
	
}

sub amora
{
	my ($kernel,$chan) = @_;
	my $nb=int(rand(16));
	my $msg = ("\x03".$nb."AMORA AKBAR(C)");
	$main::irc->yield(privmsg => $chan,$msg);
	return;
}

sub twibby
{
	my ($kernel,$chan) = @_;
	my $msg = "Moi aussi je t'aime Twibby <3";
	$main::irc->yield(privmsg => $chan,$msg);
	return;
}

# Give me a balemboy
sub gmab
{
	my ($kernel,$chan) = @_;
	my $nb=int(rand(16));
	my $message =( "\x03".$nb."BALEMBOY");
	$main::irc->yield(privmsg => $chan,$message);
return;
}

sub current_time
{
	my ($kernel,$chan) = @_;
	my $timestamp = time();
	$main::irc->yield(privmsg => $chan,"local time : $timestamp");
}

1;
