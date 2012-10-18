#!/usr/bin/perl
use strict;	# Enforce some good programming rules

use Getopt::Long;
use Cwd;
use File::Find;
use File::stat;
use Time::localtime;

#
# fileList.pl
# 
# version 0.9
#
# Create a list of files
#
# Flags:
#
# --directory | -d	Specifies starting directory	Default is current working directory
# --[no]recurse | -[no]r	Recursively search sub-folders	Default is no recursive searching
# --filter <regex>	Process only if filename matches regex
# --output | -o <filename>	Output results to file	Default is files_YYYYMMDD.txt
# 	<filename> = STDIO outputs to <STDIO>
# --[no]path	Include full path in output	Default is to not include full path
# --[no]size	Include file size in output	Default is to not include file size
# --[no]date	Include file mod date in ouptut	Default is to not include file mod date
# --help | -?	Displays help message	Default is not to show help message
# --[no]debug	Display debugging information	Default is no debug mode
# --[no]test	Test mode - display file names but do not process	Default is no test mode
#

my ( $directory_param, $recurse_param, $help_param );
my ( $version_param, $debug_param, $test_param );
my ( $output_param, $filter_param, $path_param, $size_param, $date_param );
my ( $output_filename, $output_string );
my @MONTHS = qw( 01 02 03 04 05 06 07 08 09 10 11 12 );
my @DAYS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 );
my @HOURS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 );
my @MINUTES = qw ( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );
my @SECONDS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );

GetOptions(	'directory|d=s'	=> \$directory_param,
		'recurse|r!'	=> \$recurse_param,
		'filter=s'	=> \$filter_param,
		'output|o=s'	=> \$output_param,
		'path|P!'	=> \$path_param,
		'size|S!'	=> \$size_param,
		'date!'		=> \$date_param,
		'help|?'	=> \$help_param,
		'version'	=> \$version_param,
		'debug!'	=> \$debug_param,
		'test!'		=> \$test_param );


if ( $debug_param ) {
	print "passed parameters:\n";
	print "directory_param: $directory_param\n";
	print "recurse_param: $recurse_param\n";
	print "output_param: $output_param\n";
	print "path_param: $path_param\n";
	print "size_param: $size_param\n";
	print "date_param: $date_param\n";
	print "version_param: $version_param\n";
	print "debug_param: $debug_param\n";
	print "test_param: $test_param\n";
	print "\n";
}

# If user asked for help, display help message and exit
if ( $help_param ) {
	print "fileList.pl\n\n";
	print "version 0.9\n\n";
	print "Create a list of files\n\n";
	print "Acceptable flags:\n\n";
	print "--directory | -d [<directory>] - set starting directory\n";
	print "default is the current working directory\n\n";
	print "--[no]recurse | -[no]r - recursive directory search\n";
	print "default is starting directory only (no recursion)\n\n";
	print "--filter <regex> - specifies a filename filter for processing\n";
	print "<regex> is a regular expression\n\n";
	print "--output | -o <filename> - output to file <filename>\n";
	print "If omitted, filelist_YYYYMMDD is created in starting directory\n";
	print "Use --output STDIO to output to console\n\n";
	print "--[no]path - use full path name\n";
	print "Default is to not use full path name\n\n";
	print "--[no]size - include file size\n";
	print "Default is to not include file size\n\n";
	print "--[no]date - include file modification date\n";
	print "Default is to not include file modification date\n\n";
	print "--help | -? - display this message\n\n";
	exit;
}

if ( $version_param ) {
	print "filelist.pl version 0.9\n";
	exit;
}

# Set parameter defaults
if ( $directory_param eq undef ) { $directory_param = cwd; }	# Current working directory
if ( $recurse_param eq undef ) { $recurse_param = 0; }		# False
if ( $output_param eq undef ) {
	my $tempdate = localtime()->year + 1900 . $MONTHS[localtime()->mon] . $DAYS[localtime()->mday] . $HOURS[localtime()->hour] . $MINUTES[localtime()->min] . $SECONDS[localtime()->sec];
	$output_param = $directory_param . "/filelist_" . $tempdate . ".txt";
}
if ( $path_param eq undef ) { $path_param = 0; }		# False
if ( $size_param eq undef ) { $size_param = 0; }		# False
if ( $date_param eq undef ) { $date_param = 0; }		# False
if ( $debug_param eq undef ) { $debug_param = 0; }		# False
if ( $test_param eq undef ) { $test_param = 0; }		# False

if ( $debug_param ) {
	print "adjusted parameters:\n";
	print "directory_param: $directory_param\n";
	print "recurse_param: $recurse_param\n";
	print "output_param: $output_param\n";
	print "path_param: $path_param\n";
	print "size_param: $size_param\n";
	print "date_param: $date_param\n";
	print "version_param: $version_param\n";
	print "debug_param: $debug_param\n";
	print "test_param: $test_param\n";
	print "\n";
}

$output_string = "";			# Empty the output string
chdir( $directory_param );		# Change to the target directory
find( \&doittoit, "." ); 		# Do the file filtering

if ( ! $test_param ) {			# If we're not in test mode, create the file
	# Output the results to file or STDIO
	if ( $ output_param eq "STDIO" ) { print $output_string; }
	else {
		open( OUTPUT_FILE, ">", $output_param )			# open output file
			or die "Can't create output file\n";
		print( OUTPUT_FILE $output_string );
		close( OUTPUT_FILE );
	}
}

sub doittoit {
	# Check to see if each file is in the target directory of a subdirectory
	# If recursion is on, process all of the files
	if ( ( ( $recurse_param || $File::Find::dir eq "." ) && ( ! -d ) ) &&
	( $filter_param eq undef || ( ( $filter_param ne undef ) && ( /$filter_param/ ) ) ) ) {
		# Get some information about the item
		#	Full path of item
		#	Full path of parent directory
		#	Branch (name of parent directory's parent directory - may be empty)
		#	Twig (name of parent directory)
		#	Leaf (name of file or directory)
		my ( $full_path, $parent_dir, $leaf_name, $twig_name, $branch_name, $work_space );
		
		$full_path = $directory_param . "/" . $File::Find::name;	# Create full path
		$full_path =~ s/\\/\//g;					# Turn around any backwards slashes
		if ( -d ) { $full_path .= "/"; }				# Add slash to end of the path if it is a directory
		$full_path =~ s/\/.\//\//;					# Remove extra "/./"
		$full_path =~ s/\/\//\//g;					# Remove any duplicate slashes
				
		$parent_dir = $full_path;
		$parent_dir =~ s/\/$//g;					# Strip any trailing slash
		$parent_dir =~ s/\/([^\/]+)$//;					# Delete and remember anything after after the last non-empty slash
		$leaf_name = $1;
		
		$work_space = $parent_dir;
		$work_space =~ s/\/([^\/]+)$//g;
		$twig_name = $1;
		$work_space =~ s/\/([^\/]+)$//g;
		$branch_name = $1;
		
		# Also get file size and modified date
		my $file_stat = stat( $full_path );
		my $file_size = $file_stat->size;
		my $file_mod = scalar( CORE::localtime( $file_stat->mtime ) );
		
		if ( $path_param ) { $output_string .= "$full_path"; }
		else { $output_string .= "$leaf_name"; }

		if ( $size_param ) { $output_string .= "\t$file_size"; }
		if ( $date_param ) { $output_string .= "\t$file_mod"; }
		$output_string .= "\n";
		
		if ( $debug_param ) {
			print "File $leaf_name size: $file_size\n";
			print "File $leaf_name modified date: $file_mod\n";
		}
		
		## Example - report back file names
		if ( $test_param ) {
			print "Full Path: $full_path\n";
			print "Parent Dir: $parent_dir\n";
			print "Leaf Name: $leaf_name\n";
			print "Twig Name: $twig_name\n";
			print "Branch Name: $branch_name\n";
			print "\n";
		}
	}
}
