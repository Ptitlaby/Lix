#!/usr/bin/perl

package functions::admin;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(admin_kick admin_join admin_leave admin_channel admin_nick);

# Kick someone
sub admin_kick
{
	my ($kernel,$chan,$params,$user,$user_mask) = @_;
	if (($user eq $main::admin) or ($user_mask eq $main::admin_mask))
	{
		my @words = split(/ /, $params);
		my $number_of_parameters = @words;
		if ($number_of_parameters < 2)
		{
			$main::irc->yield(privmsg => $chan,"Usage : !kick <chan> <nick>");
		}
		else
		{
				my $chan_to_kick = $words[0];
				my $nick_to_kick = $words[1];
				$main::irc->yield(kick => $chan_to_kick,$nick_to_kick);	
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"You are not high enough to do that ".$user);
	}
}

sub admin_nick
{
	my ($kernel,$chan,$params,$user,$user_mask) = @_;
	if (($user eq $main::admin) or ($user_mask eq $main::admin_mask))
	{
		$main::irc->yield(nick => $params)
	}
}

sub admin_join
{
	my ($kernel,$chan,$params,$user,$user_mask)= @_;
	$main::irc->yield(privmsg => '#lix','param :'. $params);
	if (($user eq $main::admin) or ($user_mask eq $main::admin_mask))
	{
		$main::irc->yield(join => $params)
	}
}

sub admin_channel
{
	my ($kernel,$chan,$params,$user,$user_mask)= @_;

	my $message;
	for my $channel ( keys %{ $main::irc->channels() } ) 
	{
     	$message = $message.' '.$channel;
     }
    $main::irc->yield( 'privmsg' => '#lix' => $message );
}

sub admin_leave
{
	my ($kernel,$chan,$params,$user,$user_mask)= @_;
	if (($user eq $main::admin) or ($user_mask eq $main::admin_mask))
	{
		$main::irc->yield(part => $params);
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"You are not high enough to do that ".$user);
	}
}

sub admin_op
{
	my ($kernel,$chan,$params,$user,$user_mask) = @_;
	#$main::irc->yield(privmsg => $chan,"Starting the OP command ".$user);
	if (($user eq $main::admin) or ($user_mask eq $main::admin_mask))
	{
		my @words = split(/ /, $params);
		my $number_of_parameters = @words;
		if ($number_of_parameters < 2)
		{
			$main::irc->yield(privmsg => $chan,"Usage : !op <chan> <nick>");
		}
		else
		{
				my $chan_to_op = $words[0];
				my $nick_to_op = $words[1];
				$main::irc->yield(mode => $chan_to_op => '+o' => $nick_to_op)
				#$main::irc->yield(operator => $chan_to_op,$nick_to_op);	
		}
	}
	else
	{
		$main::irc->yield(privmsg => $chan,"You are not high enough to do that ".$user);
	}
}

1;
