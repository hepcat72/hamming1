#Makefile.PL version 1.1 for CFF

require 5.000;
use ExtUtils::MakeMaker;
my @scripts = qw(mergeSeqs.pl neighbors.pl errorRates.pl nZeros.pl getCandidates.pl getReals.pl filterIndels.pl cff2qiime.pl interestingPairs.pl run_CFF_on_FastA.tcsh run_CFF_on_FastQ.tcsh);




#Check the dependent command line executables

if(incompatibleMuscle(getExe('muscle')))
  {print STDERR ("WARNING: Muscle appears to be missing or potentially incompatible.  ",
                 "Installation will proceed, but in order to run filterIndels.pl without ",
                 "errors, you must install a compatible version of muscle and put it in ",
                 "your path.  Everything else will work fine.\n")}

if(incompatibleUsearch(getExe('usearch')))
  {print STDERR ("WARNING: usearch appears to be missing or potentially incompatible.  ",
                 "Installation will proceed, but in order to run getReals.pl (with -f) ",
                 "to filter chimeric sequences or interestingPairs.pl to find dynamically ",
                 "similar abundance traces without errors, you must install a compatible ",
                 "version of usearch and put it in your path.  Everything else will work ",
                 "fine.\n")}




#Write the make file

WriteMakefile
  (
   NAME => 'CFF',
   ($[ >= 5.005) ?
   (AUTHOR   => 'Robert W. Leach (rleach@genomics.princeton.edu)',
    ABSTRACT => 'Determine which sequences are real in a metagenomic sample.') : (),
   VERSION   => "2.0",
   PREREQ_PM => {'Getopt::Long'              => 2.38,
                 'File::Glob'                => 1.17,
                 'File::Which'               => 1.09, #OPTIONAL All scripts use `which` without it
                 'IPC::Open3'                => 1.12, #OPTIONAL for filterIndels.pl
                 'IO::Select'                => 1.21, #OPTIONAL for filterIndels.pl & interestingPairs.pl
                 'IO::Pipe::Producer'        => 2.0,  #OPTIONAL for filterIndels.pl & interestingPairs.pl
                 'Sys::Info'                 => 0.78, #OPTIONAL for filterIndels.pl & interestingPairs.pl
                 'Sys::MemInfo'              => 0.91, #OPTIONAL for filterIndels.pl
                 'Math::Random'              => 0.71  #OPTIONAL for interestingPairs.pl
                },
   EXE_FILES => [ map { "src/$_" } @scripts ]
  );






#Subroutines

sub incompatibleMuscle
  {
    my $muscle = $_[0];

    if(!defined($muscle) || $muscle eq '' || !-e $muscle || !-x $muscle)
      {
	print STDERR ("ERROR: The muscle executable [$muscle] appears to either not be in ",
		      "your path, not exist, not have execute permissions, or you ",
		      "have not created a symbolic link named 'muscle' to the full ",
		      "name of the executable with version number.  If you have not ",
		      "installed muscle, you can find it here: http://www.drive5.com/",
		      "muscle/downloads.htm\n");
	return(1);
      }

    my $version = `$muscle -version`;
    chomp($version);
    if($version =~ /MUSCLE v(\S+) by Robert C. Edgar/)
      {
	my $vnum = $1;
	my $confirmed = [3,8,31];
	my $vnums = [split(/\./,$vnum,-1)];
	my $ok = 1;
	my $i = 0;
	for($i = 0;$i < scalar(@$vnums) && $i < scalar(@$confirmed);$i++)
	  {
	    if($vnums->[$i] != $confirmed->[$i])
	      {
		if($vnums->[$i] < $confirmed->[$i])
		  {$ok = 0}
		else
		  {$ok = 1}
		last;
	      }
	  }
	print STDERR ("WARNING: This script was tested with Muscle version 3.8.31.  ",
		      "Your version appears to be [$vnum], thus it may not work ",
		      "properly.\n") unless($ok);
      }
    else
      {print STDERR ("WARNING: This script was tested with Muscle version 3.8.31.  It may ",
		     "not work properly with the version you are using.\n")}

    return(0);
  }

sub incompatibleUsearch
  {
    my $usearch = $_[0];
    my $exe     = $usearch;
    $exe        =~ s/ .*//;

    if(!defined($usearch) || $usearch eq '' || !-e $exe || !-x $exe)
      {
	print STDERR ("ERROR: The usearch executable [$exe] appears to either not be in ",
	              "your path, not exist, not have execute permissions, or you ",
	              "have not created a symbolic link named 'usearch' to the full ",
	              "name of the executable with version number.  If you have not ",
	              "installed usearch, you can find it here: http://www.drive5.com/",
                      "usearch/download.html\n");
	return(1);
      }

    my $version = `$exe -version`;
    chomp($version);
    if($version =~ /usearch v(\S+)/)
      {
	my $vnum = $1;
	my $confirmed = [3,8,31];
	my $vnums = [split(/\.|_/,$vnum,-1)];
	my $ok = 1;
	my $i = 0;
	for($i = 0;$i < scalar(@$vnums) && $i < scalar(@$confirmed);$i++)
	  {
	    if($vnums->[$i] != $confirmed->[$i])
	      {
		if($vnums->[$i] < $confirmed->[$i])
		  {$ok = 0}
		else
		  {$ok = 1}
		last;
	      }
	  }
	print STDERR ("WARNING: This script was tested with usearch version ",
		      "7.0.1090_i86osx32.  Your version appears to be [$vnum], ",
		      "thus it may not work properly.\n") unless($ok);
      }
    else
      {print STDERR ("WARNING: This script was tested with usearch version ",
	             "7.0.1090_i86osx32.  It may not work properly with the ",
	             "version you are using.\n")}

    return(0);
  }

sub getExe
  {
    my $command  = $_[0];
    my $sent_exe = $command;
    $sent_exe    =~ s/ .*//;
    my $exe      = '';

    if(eval("use File::Which;1;") ||
       eval("use local::lib;use File::Which;1;"))
      {
	$exe = which($sent_exe);
	if((!defined($exe) || $exe eq '') && -e $sent_exe && -x $sent_exe)
	  {$exe = $sent_exe}
	elsif(!defined($exe))
	  {$exe = ''}
      }
    else
      {
	print STDERR ("File::Which not found, switching to backup method.\n");
	$exe = `which $sent_exe`;
	chomp($exe);
	if($exe =~ /which: Command not found./ || $exe !~ /\S/)
	  {
	    print STDERR ("ERROR: System command 'which' does not appear to exist.  Please ",
		          "install the perl module File::Which.\n");
	    $exe = '';
	  }
	elsif($exe =~ /not found/i)
	  {$exe = ''}
      }

    return($exe);
  }
