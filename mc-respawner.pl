#!/usr/bin/perl -w
use strict;

my $sleeptime = 40;

my @processlist = `ps aux |grep java |grep -v grep|grep FTBServer`;

unless (scalar @processlist >= 1){
	print "MC is not running, so running stop and start commands\n";
	system("/etc/init.d/minecraft-init.sh stop");
	sleep($sleeptime);
	system("/etc/init.d/minecraft-init.sh start");
}

