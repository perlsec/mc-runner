#!/usr/bin/perl -w
use strict;
use Perlsec::Helper ':all'; 
use Switch; #part of core perl

## INFO
# Author: Kim Jørgensen (github.com/perlsec | perlsec.dk)
# Version 0.3
## DEPENDENCIES ##
# Perlsec::Helper - helper lib from http://github.com/perlsec/perl-helper
# screen package - runs the java server in screen to keep ability to send commands to the server
# java (oracle version 1.6 or 1.7)
# minecraft jar
# root+CLI on server
## OPTIONAL ##
# c10t - for map generation extra features- http://toolchain.eu/project/c10t 
##

# Basic config
my $memory_limit = "26G"; #memory limits for java
my $data_dir = "/opt/mc/"; #where minecraft world files are located
my $minecraft_start_cmd = "/opt/java/bin/java -server -Xms$memory_limit -Xmx$memory_limit -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -jar FTBServer-1.7.10-1448.jar nogui";
my $servlog = "$data_dir/logs/latest.log";
#Backup config
my $backup_dir = "$data_dir/backup"; #where to store the packaged backups (.tgz files)
my $backup_limit = 100; # how many backups to store - a little over a months worth at 4 hour interval
#Map config
my $c10t_path = " /usr/local/src/c10t-unstable/build/c10t"; #c10t executeable path
my $map_output_dir = "/var/www"; #where to put the completed maps
my $map_archive_dir = "/var/www/map-archive"; #set this to /dev/null to not archive maps (maps are versioned with the same number as the backups)

if (!@ARGV){
 die "need commands (start|stop|status|backup|genmap|list)";
}

&_verify_and_set_backup_counter();

my $command = $ARGV[0];

switch ($command) {
	case "start" {&mcstart()}
	case "stop" {&mcstop()}
	case "hello" {&hello()}
	case "backup" {&mcbackup()}
	case "genmap" {&mcgenmap}
	case "status" {&mcstatus()}
	case "list" {&mclist()}
	case "post" {&_say($ARGV[1])}
	else { say "command not understood" }
}

######## SUBS ##########

sub mcbackup(){
	#backup to local disk
	&_say("Starting backup");
	&_mc_exec("save-off");
	sleep(3);
	my $current_backup = get_flag("current_mc_backup");
	say "current backup nr: $current_backup";
	$current_backup++;
	system("tar -cf $backup_dir/world-$current_backup.tgz $data_dir/world");
	system("ls -lhot $backup_dir/*");
	set_flag("current_mc_backup", $current_backup);
	&_mc_exec("save-on");
	&_cleanup_backups();
	&_say("Backup complete");
}

sub mcgenmap(){
	system('echo "i started" && date');
	my $backup_version = get_flag("current_mc_backup");
	my $previous_version = $backup_version - 1;
	my $genmap_cmd = "$c10t_path -R 150 -m 2 -M 6000 -s -z -w $data_dir/world -o $map_output_dir/map-new.png";
 	my $genmap_cmd2 = "$c10t_path -R 150 -m 2 -M 6000 -s -w $data_dir/world -o $map_output_dir/map-o-new.png";
	#move old map into archive with version name (current -1)
	my $cp_old_cmd = "cp $map_output_dir/map.png $map_archive_dir/map-$previous_version.png";
	my $cp_old_cmd2 = "cp $map_output_dir/map-o.png $map_archive_dir/map-o-$previous_version.png";
	system($cp_old_cmd);
 	system($cp_old_cmd2);
	#generate new maps and replace old map with new map 	
	system("time " . $genmap_cmd);
	system("time " . $genmap_cmd2);
	my $rollout_new_map = "mv $map_output_dir/map-new.png $map_output_dir/map.png";
 	my $rollout_new_map2 = "mv $map_output_dir/map-o-new.png $map_output_dir/map-o.png";
	system($rollout_new_map);
	system($rollout_new_map2);
	&_say("Generated new map for backup nr: $backup_version");
	system('echo "i stopped" && date');
}

sub mcstart(){
	if(&_check_mc_is_running()){
		say "Minecraft is already running";
	}
	else{
		say "Starting Minecraft";
		system("cd $data_dir && screen -d -m -S mc");
		&_mc_exec($minecraft_start_cmd);
	}
}

sub mcstop(){
	say "stopping minecraft";
	&_say("Stopping server in 10 seconds, saving map");
	&_mc_exec("save-all");
	&_mc_exec("stop");
	sleep(10);
	system("killall -v screen");
	say "Stopped";
}

sub mcstatus(){
	if(&_check_mc_is_running()){
		say "ON: Minecraft is running!";
		exit 0;
	}
	say "OFF: Minecraft is NOT running";
	exit 1;
}

sub mclist(){
	my @return = &_mc_exec('list');
}

######## INTERNAL SUBS ##########

sub _check_mc_is_running(){
	my @processes = `ps -A x`;
	foreach my $processline (@processes){
		if($processline =~ m/java.*FTBServer/){
			return 1;
		}
	}
	return 0;
}


sub _mc_exec(){
	my $cmd = shift;
	system("screen -p 0 -X eval 'stuff \"$cmd\"\015'");
}

sub _say(){
	my $msg = shift;
	&_mc_exec("say $msg");
}

sub _verify_and_set_backup_counter(){
	#check if the backup_counter is set, or else set it (tmp flag file is removed on reboot)
	my $backup_version = get_flag("current_mc_backup");
	if($backup_version == 0){
		my ($backup_nr) = &_get_backup_volumes_data();
		say "no flag set for backup, setting it to: $backup_nr";
		set_flag("current_mc_backup", $backup_nr);
	}
}

sub _get_backup_volumes_data(){
	my @filelist = glob("$backup_dir/world-*.tgz");
	my %volumes; #list of volumes
	my $volume_count = @filelist;
	my $backup_nr = 0;
	foreach my $file (@filelist){
		#get nr, check if its bigger then the any i have seen, store it
		if($file =~ m/world-([0-9]+).tgz/){
			my $tmp_nr = $1;
			$volumes{$tmp_nr} = $file;
			$backup_nr = $tmp_nr if ($tmp_nr > $backup_nr);
		}
	}
	return $backup_nr, $volume_count, %volumes;
}

sub _get_volumes_to_purge(){
	#nrs to keep max/min
	my $max_nr = shift;
	my $min_nr = $max_nr - $backup_limit;
	my %volumes = @_;
	my @volumes_to_purge;
	#define the volumes we want to keep, push the rest to the purge list
	foreach my $volumenr (keys %volumes){
		if($volumenr < $min_nr){
			push(@volumes_to_purge, $volumes{$volumenr});
		}
	}
	return @volumes_to_purge;
}

sub _cleanup_backups(){
	my ($backup_nr, $backups, %volumes) = &_get_backup_volumes_data();
	if ($backups > $backup_limit){
		#Too many volumes, need to purge some
		say "Cleanining backup files";
		my @volumes_to_purge = &_get_volumes_to_purge($backup_nr, %volumes);
		foreach my $vol (@volumes_to_purge){
			say "Purging file: $vol";
			unlink($vol);
		}
		print "\n----------------------\n";
	}	
}
