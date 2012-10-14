#!/usr/bin/perl
use strict;
use Perlsec::Helper ':all'; 
use Switch; #part of core perl

## INFO
# author: Kim Jørgensen (github.com/perlsec | perlsec.dk)
## DEPENDENCIES ##
# Perlsec::Helper - helper lib from http://github.com/perlsec/perl-helper
# screen package - runs the java server in this
# java (oracle version)
# minecraft jar
# root+CLI on server
# optional -
# c10t - for map generation extra features- http://toolchain.eu/project/c10t 
## ##
my $memory_limit = "6G"; #memory limits for java
my $data_dir = "/opt"; #where minecraft world files are located
my $minecraft_start_cmd = "/usr/bin/java -Xms$memory_limit -Xmx$memory_limit -jar $data_dir/minecraft_server.jar nogui"; #command to run the server
my $servlog = "$data_dir/server.log";
my $backup_dir = "$data_dir/backup";
my $c10t_path = " /usr/local/src/c10t-unstable/build/c10t";
my $map_output_dir = "/var/www";
my $map_archive_dir = "/var/www/map-archive"; #set this to /dev/null to not archive maps (maps are versioned with the same number as the backups)

if (!@ARGV){
 die "need commands (start|stop|status|backup|genmap|list)";
}

my $command = $ARGV[0];

switch ($command) {
	case "start" {&mcstart()}
	case "stop" {&mcstop()}
	case "hello" {&hello()}
	case "backup" {&mcbackup()}
	case "genmap" {&mcgenmap}
	case "status" {&mcstatus()}
	case "list" {&mclist()}
	else { say "command not understood" }
}

######## SUBS ##########

sub mcbackup(){
   #backup to local disk
	&_say("Starting backup");
	&_mc_exec("save-off");
	sleep(3);
	my $current_backup = get_flag("current_mc_backup");
	say "curr: $current_backup";
	$current_backup++;
	system("tar -cf $backup_dir/world-$current_backup.tgz $data_dir/world");
	system("du -hsc $backup_dir/*");
	set_flag("current_mc_backup", $current_backup);
	&_mc_exec("save-on");
	&_say("Backup complete");
}

sub mcgenmap(){
	my $backup_version = get_flag("current_mc_backup");
	my $previous_version = $backup_version - 1;
	my $genmap_cmd = "$c10t_path -m 2 -M 6000 -s -z -w $data_dir/world -o $map_output_dir/map-new.png";
 	my $genmap_cmd2 = "$c10t_path -m 2 -M 6000 -s -w $data_dir/world -o $map_output_dir/map-o-new.png";
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
}

sub mcstart(){
	if(&_check_mc_is_running()){
		say "Minecraft is already running";
	}
	else{
		say "Starting Minecraft";
		system("screen -d -m");
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

sub hello(){
	&_say("mjello");
}

sub _check_mc_is_running(){
	my @processes = `ps -A x`;
	foreach my $processline (@processes){
		if($processline =~ m/java.*minecraft/){
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
