#!/usr/bin/perl -w
use strict;
use warnings;

use POE;
use POE::Component::IRC;
use POE::Component::SSLify;
use POE qw(Component::IRC::State);

use DBD::mysql;

use Module::Reload;


# Config file with passwords
# @EXPORT = qw($password_nick);
use password; 


my $database = ('eleve_tellier');
my $db_username = ('eleve_tellier');

my $dbhost = ('mysql.iiens.net');
my $socket = ('/var/run/mysql/mysql.sock');

# Module handling the commands
use functions::commands;
use functions::votekick;
use functions::irc_events;
use functions::quote;
use functions::help;


# nom du fichier
my $bot = $0;

# config
my $serveur = 'IRC.iiens.net';
my $nick = 'Lix-dev';
my $port = 7000;
my $ircname = 'Lix-dev';
my $username = 'Lix-dev';
our @channels = ('#Lix');

our $admin = 'Laby';
our $admin_mask = 'laby@giboulees.net';


my $ssl_certificate = '/etc/ssl/arise/cacert_arise.crt';

## CONNEXION 
our ($irc) = POE::Component::IRC::State->spawn(
      Nick     => $nick,
      Username => $username, 
      Ircname  => $ircname,
      Server   => $serveur,
      Port     => $port,
      UseSSL   => 1,
      SSLCert  => $ssl_certificate,
	);



# Evenements que le bot va gérer
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,

    irc_001    => \&functions::irc_events::on_connect
,
    irc_registered => \&functions::irc_events::on_registered,
    irc_shutdown => \&functions::irc_events::on_shutdown,
    irc_connected => \&functions::irc_events::on_connected,
    irc_ctcp => \&functions::irc_events::on_ctcp,
    irc_disconnected => \&functions::irc_events::on_disconnected,
    irc_error => \&functions::irc_events::on_error,
    irc_join => \&functions::irc_events::on_join,
    irc_invite => \&functions::irc_events::on_invite,
    irc_kick => \&functions::irc_events::on_kick,
    irc_mode => \&functions::irc_events::on_mode,
    irc_msg => \&functions::irc_events::on_msg,
    irc_nick => \&functions::irc_events::on_nick,
    irc_notice => \&functions::irc_events::on_notice,
    irc_part => \&functions::irc_events::on_part,
    irc_public => \&functions::irc_events::on_public,
    irc_quit => \&functions::irc_events::on_quit,
    irc_socketerr => \&functions::irc_events::on_socketerr,
    irc_topic => \&functions::irc_events::on_topic,
    irc_whois => \&functions::irc_events::on_whois,
    irc_whowas => \&functions::irc_events::on_whowas,
    irc_delay_set => \&functions::irc_events::on_delay_set,
    irc_delay_removed => \&functions::irc_events::on_delay_removed,

    #_cycle => \&cycle_sub,
    _votekick_check => \&functions::votekick::checkvotekick,
    #_rss_update => \&functions::rss::rss_update,
  },
);




## GESTION EVENTS

# Au démarrage

sub bot_start {
	$irc->yield(register => "all");
	$irc->yield(connect => {});
	$irc->yield(privmsg => "NickServ","IDENTIFY $password_nick");
  
}

sub cycle_sub
{
	my $kernel = $_[ KERNEL ];
	$irc->yield(privmsg => "#lix","Bip bip");
	$kernel->delay_set('_cycle', 60);
}




sub reload_modules
{
    Module::Reload->check;
    $main::irc->yield(privmsg => "#lix","Module reloaded");

}

# Boucle des events
$poe_kernel->run();
exit 0;