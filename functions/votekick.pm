#!/usr/bin/perl

package functions::votekick;

use strict;
use warnings;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(votekick votekick_yes votekick_no votekick_maybe checkvotekick);


# Variables for the votekick
my $is_votekick_running = 0;
my $votekick_yes = 0;
my $votekick_name_list ='';
my $votekick_no = 0;
my $votekick_to_kick='';
my $votekick_chan='';
my $votekick_starter='';
my $delay_votekick = 20;
my $color_yes = 9;
my $color_no = 4;
my $color_nick = 8;
my @dont_kick = ($main::admin,"Balembot","gizmo");


sub votekick
{
	$main::irc->yield(privmsg => "#lix","function call");
	use vars qw($is_votekick_running);
	use vars qw($votekick_yes);
	use vars qw($votekick_yes_name_list);
	use vars qw($votekick_no);
	use vars qw($votekick_no_name_list);
	use vars qw($votekick_to_kick);
	use vars qw($votekick_user_to_kick);
	use vars qw($votekick_host_to_kick);
	use vars qw($votekick_chan);
	use vars qw($votekick_starter);
	use vars qw($votekick_looking_new_name);
	use vars qw($delay_votekick);

	$votekick_looking_new_name = 0;

	my ($kernel,$chan,$param,$user) = @_;
	$param =~ s/^\s+//;
	$param =~ s/\s+$//;

	my @people_on_chan;
	@people_on_chan = $main::irc->channel_list($chan);
	my $nick_to_kick;
	my $surprise = 0;
	if ( !defined($param) )
	{
		my $arraySize = scalar (@people_on_chan);
		my $random_number = int(rand($arraySize));
		$nick_to_kick=$people_on_chan[$random_number];
		$surprise = 1;
	}
	else
	{
		$param =~ s/[# ! ^ $ ( ) \[ \] { } ? + * . \\ | ]/\\$&/g;
		$nick_to_kick = $param;
	}
	if ( grep( /^\b$nick_to_kick\b$/i, @people_on_chan ) )
	{
		if ( $is_votekick_running == 0)
		{
			$votekick_chan = $chan;
			$votekick_starter = $user;
			if ($surprise == 0)
			{ 
				$main::irc->yield(privmsg => $chan,"Votekick launched for ".$nick_to_kick);
			}
			else
			{
				$main::irc->yield(privmsg => $chan,"Votekick surprise launched !");

			}
			$votekick_to_kick = $nick_to_kick;
			$is_votekick_running = 1;
			$kernel->delay_set('_votekick_check', $delay_votekick);
		}
		else
		{
			$main::irc->yield(privmsg => $chan,"Votekick already running on ".$votekick_chan);
		}
	}

}


sub checkvotekick
{
	use vars qw($is_votekick_running);
	use vars qw($votekick_yes);
	use vars qw($votekick_yes_name_list);
	use vars qw($votekick_no);
	use vars qw($votekick_no_name_list);
	use vars qw($votekick_to_kick);
	use vars qw($votekick_chan);

	if ( $votekick_yes > $votekick_no )
	{
		
		if ( grep( /^\b$votekick_to_kick\b$/i, @dont_kick ) )
		{
			$main::irc->yield(kick => $votekick_chan,$votekick_starter);
		}
		else
		{
			$main::irc->yield(kick => $votekick_chan,$votekick_to_kick);
			my $message =( "Votekick successful for \x03".$color_nick."".$votekick_to_kick."\x03:\x03".$color_yes." ".$votekick_yes." Yes\x03 and\x03".$color_no." ".$votekick_no." No");
			$main::irc->yield(privmsg => $votekick_chan,$message);

		}

	}
	else
	{
		my $message =( "Votekick failed for \x03".$color_nick."".$votekick_to_kick."\x03:\x03".$color_yes." ".$votekick_yes." Yes\x03 and\x03".$color_no." ".$votekick_no." No");
		$main::irc->yield(privmsg => $votekick_chan,$message);
	}

	$is_votekick_running = 0;
	$votekick_yes = 0;
	$votekick_no = 0;
	$votekick_name_list = '';
}

sub votekick_yes
{
	use vars qw($is_votekick_running);
	use vars qw($votekick_yes);
	use vars qw($votekick_name_list);
	use vars qw($votekick_no);
	use vars qw($votekick_to_kick);
	use vars qw($votekick_chan);
	use vars qw($votekick_user_to_kick);
	use vars qw($votekick_host_to_kick);

	my ($kernel,$chan,$msg,$user) = @_;
	if ( $is_votekick_running == 1 )
	{
		if (!($votekick_name_list =~ $user))
		{
			$votekick_yes = $votekick_yes + 1;
			$votekick_name_list = $votekick_name_list.' '.$user;
		}
	}
}


sub votekick_no
{
	use vars qw($is_votekick_running);
	use vars qw($votekick_yes);
	use vars qw($votekick_name_list);
	use vars qw($votekick_no);
	use vars qw($votekick_to_kick);
	use vars qw($votekick_chan);
	use vars qw($votekick_user_to_kick);
	use vars qw($votekick_host_to_kick);

	my ($kernel,$chan,$msg,$user) = @_;
	if ( $is_votekick_running == 1 )
	{
		if (!($votekick_name_list =~ $user))
		{
			$votekick_no = $votekick_no + 1;
			$votekick_name_list = $votekick_name_list.' '.$user;
		}
	}
}

sub votekick_maybe
{
	use vars qw($is_votekick_running);
	use vars qw($votekick_yes);
	use vars qw($votekick_name_list);
	use vars qw($votekick_no);
	use vars qw($votekick_no_name_list);
	use vars qw($votekick_to_kick);
	use vars qw($votekick_chan);
	use vars qw($votekick_user_to_kick);
	use vars qw($votekick_host_to_kick);

	my ($kernel,$chan,$msg,$user) = @_;
	if ( $is_votekick_running == 1 )
	{
		my $random_number = int(rand(100));
		if ( $random_number < 50 )
		{
			if (!($votekick_name_list =~ $user))
			{
				$votekick_no = $votekick_no + 1;
				$votekick_name_list = $votekick_name_list.' '.$user;
			}
		}
		else
		{
			if (!($votekick_name_list =~ $user))
			{
				$votekick_yes = $votekick_yes + 1;
				$votekick_name_list = $votekick_name_list.' '.$user;
			}
		}
	}
	else
	{
	}

}


1;
