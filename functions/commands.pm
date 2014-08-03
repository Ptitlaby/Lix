#!/usr/bin/perl

package functions::commands;

use strict;
use warnings;

use functions::keywords;
use functions::quote;
use functions::admin;
use functions::votekick;
use functions::help;
use functions::remind;
use functions::todo;
use functions::rss;
use functions::bluff;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_commands);

sub check_commands
{
	my ($kernel,$user,$user_mask,$chan,$commande,$params)=@_;
	#$main::irc->yield(privmsg => '#lix',"call general. user : ".$user."chan : ".$chan);
	functions::help::help($kernel,$chan,$params,$user) if ( $commande eq 'help' );
		

	# Votekick commands
	functions::votekick::votekick($kernel,$chan,$params,$user) if ( $commande eq 'votekick' );
	functions::votekick::votekick_yes($kernel,$chan,$params,$user_mask) if ( $commande eq 'yes' );
	functions::votekick::votekick_no($kernel,$chan,$params,$user_mask) if ( $commande eq 'no' );
	functions::votekick::votekick_maybe($kernel,$chan,$params,$user_mask) if ( $commande eq 'maybe' );	
	functions::votekick::checkvotekick($kernel,$chan,$params,$user) if ( $commande eq 'checkvotekick' );

	#Module de quote
	functions::quote::addquote($kernel,$chan,$params,$user) if ( $commande eq 'addquote' );
	functions::quote::getquote($kernel,$chan,$params) if ( $commande eq 'getquote' );
	functions::quote::countquote($kernel,$chan,$params) if ( $commande eq 'countquote' );
	functions::quote::delquote($kernel,$chan,$params) if ( $commande eq 'delquote' );
	functions::quote::whoquote($kernel,$chan,$params) if ( $commande eq 'whoquote' );
	functions::quote::whenquote($kernel,$chan,$params) if ( $commande eq 'whenquote' );
	functions::quote::topicquote($kernel,$chan,$params,$user) if ( $commande eq 'topicquote' );

	functions::bluff::addbluff($kernel,$chan,$params,$user) if ( $commande eq 'addbluff' );
	functions::bluff::getbluff($kernel,$chan,$params) if ( $commande eq 'getbluff' );
	functions::bluff::countbluff($kernel,$chan,$params) if ( $commande eq 'countbluff' );
	functions::bluff::delbluff($kernel,$chan,$params) if ( $commande eq 'delbluff' );
	functions::bluff::whobluff($kernel,$chan,$params) if ( $commande eq 'whobluff' );
	functions::bluff::whenbluff($kernel,$chan,$params) if ( $commande eq 'whenbluff' );
	functions::bluff::topicbluff($kernel,$chan,$params,$user) if ( $commande eq 'topicbluff' );



	#Remind
	#functions::remind::remind($kernel,$chan,$params,$user) if ($commande eq 'remind');
	#functions::remind::clean_remind() if ($commande eq 'clean_remind');
	#functions::remind::load_reminds() if ($commande eq 'load_reminds');
	
	#Admin commands
	functions::admin::admin_join($kernel,$chan,$params,$user,$user_mask) if ($commande eq 'join' );
	functions::admin::admin_leave($kernel,$chan,$params,$user,$user_mask) if ($commande eq 'leave' );
	functions::admin::admin_kick($kernel,$chan,$params,$user,$user_mask) if ( $commande eq 'kick' );
	functions::admin::admin_op($kernel,$chan,$params,$user,$user_mask) if ( $commande eq 'op' );
	functions::admin::admin_nick($kernel,$chan,$params,$user,$user_mask) if ( $commande eq 'nick' );
	functions::admin::admin_channel($kernel,$chan,$params,$user,$user_mask) if ( $commande eq 'chans' );

	# Todo
	functions::todo::addtodo($kernel,$chan,$params,$user) if ( $commande eq 'addtodo' );
	functions::todo::todo($kernel,$chan,$params,$user) if ( $commande eq 'todo' );
	functions::todo::deltodo($kernel,$chan,$params,$user) if ( $commande eq 'deltodo' );

	#module rss
	#functions::rss::rss($kernel,$chan,$params,$user) if ( $commande eq 'rss' );
	#functions::rss::rss_add($kernel,$chan,$params,$user) if ( $commande eq 'rss_add' );
	#functions::rss::rss_see($kernel,$chan,$params,$user) if ( $commande eq 'rss_see' );
	#functions::rss::rss_del($kernel,$chan,$params,$user) if ( $commande eq 'rss_del' );
	#functions::rss::rss_edit($kernel,$chan,$params,$user) if ( $commande eq 'rss_edit' );
	#functions::rss::rss_refresh($kernel,$chan,$params,$user) if ( $commande eq 'rss_refresh' );

	

	
	functions::keywords::laby($kernel,$chan) if (lc($commande) eq 'laby');
	functions::keywords::amora($kernel,$chan) if (lc($commande) eq 'amora');
	functions::keywords::gmab($kernel,$chan) if ( $commande eq 'gmab' );
	functions::keywords::current_time($kernel,$chan) if ( $commande eq 'time' );
	functions::keywords::twibby($kernel,$chan) if (lc($commande) eq 'twibby');
	

}

1;

