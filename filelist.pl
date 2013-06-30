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
# version 1.2
#
# created ????
# modified 2013-06-29
#
# Create a list of files
#
# Flags:
#
# --directory | -d			Specifies starting directory	Default is current working directory
# --[no]recurse | -[no]r	Recursively search sub-folders	Default is no recursive searching
# --filter | -f <regex>		Process only if filename matches regex
# --output | -o <filename>	Output results to file	Default is files_YYYYMMDD.txt
# 								<filename> = STDIO outputs to <STDIO>
# --[no]path | -[no]p		Include full path in output	Default is to not include full path
# --[no]size | -[no]s		Include file size in output	Default is to not include file size
# --[no]date | -[no]d		Include file mod date in ouptut	Default is to not include file mod date
# --[no]hidden | -[no]h		Include hidden files (default is true)
# --level | -l <n>			Set output level
#								--level 0 is same as --nohidden --norecurse --nopath --nosize --nodate
#								--level 1 is same as --hidden --norecurse --nopath --nosize --nodate
#								--level 2 is same as --hidden --recurse --nopath --nosize --nodate
#								--level 3 is same as --hidden --recurse --path --nosize --nodate
#								--level 4 is same as --hidden --recurse --path --size --nodate
#								--level 5 is same as --hidden --recurse --path --size --date
#								overrides these flags
# --everything | -e			Get everything - all optional flags on
#								equivalent to --recurse --path --size --date --hidden (same as --level 5)
#								overrides all other flags, includuing --level
# --[no]folders				Include folders in output (default: false)
# --[no]files				Include files in output (default: true)
# --help | -?				Displays help message	Default is not to show help message
# --[no]debug				Display debugging information	Default is false
# --[no]test				Test mode - display file names but do not process	Default is false
#
#
# revsion history
#
# version 1.0
# * added option to ignore Linux/Mac OS X style "hidden" files
# * added a level preset feature
# * added a "everything" flag that defaults settings to index all files and include all information
# 
# version 1.1
# add file/folder flags to control what is included
#
# version 1.2
# fixed bug with directory filtering
#

my ( $directory_param, $recurse_param, $help_param );
my ( $version_param, $debug_param, $test_param );
my ( $output_param, $filter_param, $path_param, $size_param, $date_param );
my ( $hidden_param, $everything_param, $level_param );
my ( $folders_param, $files_param );
my ( $is_file, $is_directory );
my ( $output_filename, $output_string );
my @MONTHS = qw( 01 02 03 04 05 06 07 08 09 10 11 12 );
my @DAYS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 );
my @HOURS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 );
my @MINUTES = qw ( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );
my @SECONDS = qw( 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 );

GetOptions(	'directory|d=s'		=> \$directory_param,
			'recurse|r!'		=> \$recurse_param,
			'filter|f=s'		=> \$filter_param,
			'output|o=s'		=> \$output_param,
			'path|p!'			=> \$path_param,
			'size|s!'			=> \$size_param,
			'date|d!'			=> \$date_param,
			'hidden|h!'			=> \$hidden_param,
			'level|l=i'			=> \$level_param,
			'everything|e'		=> \$everything_param,
			'files!'			=> \$files_param,
			'folders!'			=> \$folders_param,
			'files!'			=> \$files_param,
			'help|?'			=> \$help_param,
			'version'			=> \$version_param,
			'debug!'			=> \$debug_param,
			'test!'				=> \$test_param );


if ( $debug_param ) {
	print "DEBUG: passed parameters:\n";
	print "directory_param: $directory_param\n";
	print "recurse_param: $recurse_param\n";
	print "output_param: $output_param\n";
	print "path_param: $path_param\n";
	print "size_param: $size_param\n";
	print "date_param: $date_param\n";
	print "hidden_param: $hidden_param\n";
	print "level_param: $level_param\n";
	print "everything_param: $everything_param\n";
	print "files_param: $files_param\n";
	print "folders_param: $folders_param\n";
	print "version_param: $version_param\n";
	print "debug_param: $debug_param\n";
	print "test_param: $test_param\n";
	print "\n";
}

# If user asked for help, display help message and exit
if ( $help_param ) {
	print "fileList.pl\n\n";
	print "version 1.1\n\n";
	print "Create a list of files\n\n";
	print "Acceptable flags:\n\n";
	print "--directory | -d [<directory>] - set starting directory\n";
	print "default is the current working directory\n\n";
	print "--[no]recurse | -[no]r - recursive directory search\n";
	print "default is to not index subdirectories\n";
	print "starting folder and all sub-folders will be processed\n";
	print "use --norecurse or -nor to process starting directory only\n\n";
	print "--filter | -f <regex> - specifies a filename filter for processing\n";
	print "<regex> is a regular expression\n\n";
	print "--output | -o <filename> - output to file <filename>\n";
	print "If omitted, filelist_YYYYMMDD is created in starting directory\n";
	print "Use --output STDIO to output to console\n\n";
	print "--[no]path | -[no]p - use full path name\n";
	print "Default is to not use full path name\n\n";
	print "--[no]size | -[no]s - include file size\n";
	print "Default is to not include file size\n\n";
	print "--[no]date | -[no]d - include file modification date\n";
	print "Default is to not include file modification date\n\n";
	print "--[no]hidden | -[no]h - include or suppress hidden files\n";
	print "only works on Linux/Unix/Mac style '.' files\n";
	print "by default includes hidden files in output\n";
	print "use --nohidden or -noh to suppress including hidden files\n\n";
	print "--level | -l <n> - preset level\n";
	print "--level 0 is same as --nohidden --norecurse --nopath --nosize --nodate\n";
	print "--level 1 is same as --hidden --norecurse --nopath --nosize --nodate\n";
	print "--level 2 is same as --hidden --recurse --nopath --nosize --nodate\n";
	print "--level 3 is same as --hidden --recurse --path --nosize --nodate\n";
	print "--level 4 is same as --hidden --recurse --path --size --nodate\n";
	print "--level 5 is same as --hidden --recurse --path --size --date\n";
	print "overrides --hidden, --recurse --path --size and --date flags\n\n";
	print "--everything | -e - includes everything\n";
	print "equivalent to --hidden --recurse --path --size --date (same as --level 5)\n";
	print "overrides other flags, including --level\n\n";
	print "--[no]files\n";
	print "\tinclude files in output (default: true)\n\n";
	print "--[no]folders\n";
	print "\tinclude folders in output (default: false)\n\n";
	print "--help | -? - display this message\n\n";
	exit;
}

if ( $version_param ) {
	print "filelist.pl version 1.1\n";
	exit;
}

# Set parameter defaults
if ( $directory_param eq undef ) { $directory_param = cwd; }	# Current working directory
if ( $recurse_param eq undef ) { $recurse_param = 0; }	# False
if ( $hidden_param eq undef ) { $hidden_param = 1; }	# True
if ( $output_param eq undef ) {
	my $tempdate = localtime()->year + 1900 . $MONTHS[localtime()->mon] . $DAYS[localtime()->mday] . $HOURS[localtime()->hour] . $MINUTES[localtime()->min] . $SECONDS[localtime()->sec];
	$output_param = $directory_param . "/filelist_" . $tempdate . ".txt";
}
if ( $path_param eq undef ) { $path_param = 0; }		# False
if ( $size_param eq undef ) { $size_param = 0; }		# False
if ( $date_param eq undef ) { $date_param = 0; }		# False
if ( $debug_param eq undef ) { $debug_param = 0; }		# False
if ( $test_param eq undef ) { $test_param = 0; }		# False
if ( $files_param eq undef ) { $files_param = 1; }		# True
if ( $folders_param eq undef ) { $folders_param = 0; }	# False

# Change parameters if preset is specified
if ( ( $level_param == 0 ) && ( $level_param ne undef ) ) {
	$hidden_param = 0;
	$recurse_param = 0;
	$path_param = 0;
	$size_param = 0;
	$date_param = 0;
} elsif ( $level_param == 1 ) {
	$hidden_param = 1;
	$recurse_param = 0;
	$path_param = 0;
	$size_param = 0;
	$date_param = 0;
} elsif ( $level_param == 2 ) {
	$hidden_param = 1;
	$recurse_param = 1;
	$path_param = 0;
	$size_param = 0;
	$date_param = 0;
} elsif ( $level_param == 3 ) {
	$hidden_param = 1;
	$recurse_param = 1;
	$path_param = 1;
	$size_param = 0;
	$date_param = 0;
} elsif ( $level_param == 4 ) {
	$hidden_param = 1;
	$recurse_param = 1;
	$path_param = 1;
	$size_param = 1;
	$date_param = 0;
} elsif ( $level_param == 5 ) {
	$hidden_param = 1;
	$recurse_param = 1;
	$path_param = 1;
	$size_param = 1;
	$date_param = 1;
}

# Change parameters if --everything flag is specified
if ( $everything_param ) {
	$hidden_param = 1;
	$recurse_param = 1;
	$path_param = 1;
	$size_param = 1;
	$date_param = 1;
}

if ( $debug_param ) {
	print "DEBUG: adjusted parameters:\n";
	print "directory_param: $directory_param\n";
	print "recurse_param: $recurse_param\n";
	print "output_param: $output_param\n";
	print "path_param: $path_param\n";
	print "size_param: $size_param\n";
	print "date_param: $date_param\n";
	print "hidden_param: $hidden_param\n";
	print "level_param: $level_param\n";
	print "everything_param: $everything_param\n";
	print "files_param: $files_param\n";
	print "folders_param: $folders_param\n";
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
	if ( ( ( $recurse_param || $File::Find::dir eq "." ) ) &&
	( $filter_param eq undef || ( ( $filter_param ne undef ) && ( /$filter_param/ ) ) ) ) {
		# Get some information about the item
		#	Full path of item
		#	Full path of parent directory
		#	Branch (name of parent directory's parent directory - may be empty)
		#	Twig (name of parent directory)
		#	Leaf (name of file or directory)
		my ( $full_path, $parent_dir, $leaf_name, $twig_name, $branch_name, $work_space );
		
		$is_directory = ( -d );
				
		$full_path = $directory_param . "/" . $File::Find::name;	# Create full path
		$full_path =~ s/\\/\//g;					# Turn around any backwards slashes
		if ( $is_directory ) { $full_path .= "/"; }	# Add slash to end of the path if it is a directory
		$full_path =~ s/\/\.\//\//;					# Remove extra "/./"
		$full_path =~ s/\/\//\//g;					# Remove any duplicate slashes
				
		$parent_dir = $full_path;
		$parent_dir =~ s/\/$//g;					# Strip any trailing slash
		$parent_dir =~ s/\/([^\/]+)$//;				# Delete and remember anything after after the last non-empty slash
		$leaf_name = $1;
		
		$work_space = $parent_dir;
		$work_space =~ s/\/([^\/]+)$//g;
		$twig_name = $1;
		$work_space =~ s/\/([^\/]+)$//g;
		$branch_name = $1;
		
		# Check to see if file is hidden or contained in a hidden directory
		# if it is, we should ignore it
		if ( ( !$hidden_param ) && ( $full_path =~ m/\/\./ ) ) {
			if ( $debug_param ) { print "DEBUG: file $full_path is hidden and not indexed\n"; }
			return 0;	# file was not indexed
		}
		
		# Check to see if we should index this based on --files and --folders
		if ( ( $is_directory ) && ( !$folders_param ) ) {
			if ( $debug_param ) { print "DEBUG: folder $full_path not indexed because --folders not specified\n"; }
			return 0; 	# file was not indexed
		}
		if ( ( !$is_directory ) && ( !$files_param ) ) {
			if ( $debug_param ) { print "DEBUG: file $full_path not indexed because --files not specified\n"; }
			return 0; 	# file was not indexed
		}

		# get file size and modification date
		my $file_stat = stat( $full_path );
		my $file_size = $file_stat->size;
		my $file_mod = scalar( CORE::localtime( $file_stat->mtime ) );
		
		if ( $path_param ) { $output_string .= "$full_path"; }
		else { $output_string .= "$leaf_name"; }

		if ( $size_param ) { $output_string .= "\t$file_size"; }
		if ( $date_param ) { $output_string .= "\t$file_mod"; }
		$output_string .= "\n";
		
		if ( $debug_param ) {
			print "DEBUG: file $leaf_name size: $file_size\n";
			print "DEBUG: file $leaf_name modified date: $file_mod\n";
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
		
		# if we get here, the file was indexed and added to the output
		return 1;	# file indexed
	}
}
