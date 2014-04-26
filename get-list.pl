#!/usr/bin/perl
use strict;
use Perlsec::Helper ':all';
use File::Tail; #debian package libfile-tail-perl

my $servlog = "/opt/logs/latest.log";
my $output_file = "/var/www/players-online.txt";
my $list_cmd = "/opt/minecraft-runner.pl list";

#tail logfile, with two past lines, to ensure we dont miss the output in the server log
my $file = File::Tail->new(name=>$servlog, tail=>2);

my $line;
my $list_done;

if(!$list_done){
	system($list_cmd);
	$list_done = 1;
	#print "list done\n";
}
while($line=$file->read){
	#print "l - $line";

	if( $line =~ m/\[Server thread\/INFO\].*players online.*/ ){
		$line .= $file->read; #also get next line
		#print "match header\n";
		last();
	}
}

write_to_file($output_file, $line) or die "failed $1";

exit();
