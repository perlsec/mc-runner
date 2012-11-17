#!/usr/bin/perl
use strict;
use Perlsec::Helper ':all';
use File::Tail; #debian package libfile-tail-perl

my $servlog = "/opt/server.log";
my $output_file = "/var/www/players-online.txt";
my $list_cmd = "/opt/minecraft-runner.pl list";

#tail logfile, with two past lines, to ensure we dont miss the output in the server log
my $file = File::Tail->new(name=>$servlog, tail=>2);

my $line;
my $list_done;

while($line=$file->read){
	if(!$list_done){
		system($list_cmd);
		$list_done = 1;
	}
	if( $line =~ m/\[INFO\].*players online.*/ ){
		$line .= $file->read; #also get next line
		last();
	}
}

write_to_file($output_file, $line) or die "failed $1";

exit();
