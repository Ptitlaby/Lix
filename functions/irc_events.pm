#!/usr/bin/perl

package functions::irc_events;

use strict;
use warnings;

use Module::Reload;
use functions::remind;
use functions::rss;

use Data::Dumper;

use POE;


use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(on_public on_delay_set on_delay_removed on_msg on_connect on_invite on_registered on_connected on_ctcp on_disconnected on_error on_join on_invite on_kick on_mode on_nick on_notice on_part on_quit on_socketerr on_topic on_whois on_whowas);

sub on_public
{
	my ($kernel,$user_info,$msg) = @_[KERNEL, ARG0, ARG2];
	my @chan1 = $_[ARG1];
	my $chan = $chan1[0][0];
	if ( substr($msg,0,1) eq '!' )
	{
		my $user = ( split(/!/,$user_info) )[0];
		my $user_mask = ( split(/!/,$user_info) )[1];
		my $commande = ( $msg =~ m/^!([^ ]*)/ )[0]; 
		print $msg;
		if ( $commande eq 'reload')
		{
			main::reload_modules();
		}
		else
		{
			#my @params = grep {!/^\s*$/} split(/\s+/, substr($msg, length("!$commande")));
			my $params = substr($msg, length("!$commande "));

			my @args=($kernel,$user,$user_mask,$chan,$commande,$params);
			functions::commands::check_commands(@args);
		}
	}
}

sub on_msg
{
	my ($kernel,$user_info,$msg) = @_[KERNEL, ARG0, ARG2];
	my @chan1 = $_[ARG1];
	my $chan = $chan1[0][0];
	my $user = ( split(/!/,$user_info) )[0];
	my $user_mask = ( split(/!/,$user_info) )[1];
	$main::irc->yield(privmsg => "#lix", " user : $user_mask!");
	if ( substr($msg,0,1) eq '!' )
	{
		my $user = ( split(/!/,$user_info) )[0];
		my $user_mask = ( split(/!/,$user_info) )[1];
		my $commande = ( $msg =~ m/^!([^ ]*)/ )[0]; 
		if ( $commande eq 'reload')
		{
			main::reload_modules();
		}
		else
		{
			#my @params = grep {!/^\s*$/} split(/\s+/, substr($msg, length("!$commande")));
			my $params = substr($msg, length("!$commande "));
			$main::irc->yield(privmsg => '#lix',"user : $user");
			$main::irc->yield(privmsg => '#lix',"user mask : $user_mask");
			$main::irc->yield(privmsg => '#lix',"chan : $chan");
			my @args=($kernel,$user,$user_mask,$chan,$commande,$params);
			functions::commands::check_commands(@args);
		}
	}

}

# A la connection
sub on_connect
{
	my ($kernel, $sender) = @_[KERNEL, SENDER];
	$main::irc->yield(join => @main::channels);
	#$kernel->delay_set('functions::remind::clean_remind($kernel)', 300);

	functions::remind::load_reminds();
	#$kernel->delay_set('functions::rss::rss_update($kernel)', 10);
}

sub on_connected
{
	my $kernel = $_[2];
#	functions::rss::rss_refresh($kernel);
}



# Auto invite
sub on_invite
{
	my ($kernel,$user) = @_[KERNEL, ARG0];
	my $chan = $_[ARG1];
	$main::irc->yield(join => $chan);
}


sub on_registered
{
	#the kernel is $_[2]
	my $kernel = $_[2];
	$kernel->delay_set('_rss_update',60,($kernel));

	#open (MYFILE, '>>on_registered.txt');
	#print MYFILE Dumper(@_);
	#close (MYFILE);
}


sub on_ctcp
{

}

sub on_disconnected
{

}

sub on_error
{

}

sub on_join
{
 my @array_to_kick = ("Alpha","GeonPi","Chuck","Under","Smurf","O-P","Foufoune","Rambo","frtoms","Benef","Loopy","Allo","Sky","Rafiki","Disco");

    	my ($kernel,$user_) = @_[KERNEL,ARG0];
    my $chan = $_[ARG1];
    my $user = ( split(/!/,$user_) )[0];
    my $mask = ( split(/!/,$user_) )[1];
    if ( grep( /^$user$/, @array_to_kick) )
    {
	    $main::irc->yield(kick => $chan,$user);
    }
    else
    {
    	$main::irc->yield(mode => $chan." +o", $user);
    }
}

sub on_kick
{

}

sub on_mode
{

}

sub on_nick
{

}

sub on_notice
{

}

sub on_part
{

}

sub on_quit
{

}

sub on_socketerr
{

}

sub on_topic
{

}

sub on_whois
{

}

sub on_whowas
{

}

sub on_delay_set
{

}

sub on_delay_removed
{

}
1;
