# Perl script to perform daily build and allow configuration 
#
# perl daily-build.pl 
#
# Author: R Karthik (karthik.ramanan@ti.com)
#
# 26-Jun-2010: Initial version

use File::Find;
use File::stat;
use Cwd;
use Threads;
#use strict;
#use warnings;

sub get_current_date()
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mday = sprintf("%02d", $mday);
	$year += 1900;
	$mon+= 1;
	$mon = sprintf("%02d", $mon);

	my $string = $year . $mon . $mday;
	return $string;
}

sub get_yesterday_date()
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - 86400);
	$mday = sprintf("%02d", $mday);
	$year += 1900;
	$mon+= 1;
	$mon = sprintf("%02d", $mon);

	my $string = $year . $mon . $mday;
	return $string;
}

sub get_current_time()
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$hour = sprintf("%02d", $hour);
	$min = sprintf("%02d", $min);
	$sec = sprintf("%02d", $sec);

	my $string = "$hour-$min-$sec";
	return $string;	
}

sub create_directory($)
{
	my $path = shift;
	my $command;

	if(-d $path)
	{
		print "\n Directory - $path already exists. Ignoring request to create directory";
	}
	else
	{
		$command = "mkdir $path";
		system($command);
	}
}

sub setup_directory()
{
	my $DEBUG = 0;
	$DIRNAME = get_current_date();
	$DIRNAME = $DIRNAME . "-Ducati-Daily-Build-Report";
	print "\n Directory name = $DIRNAME" if $DEBUG;

	create_directory($RESULTLOCATION);
	create_directory("$RESULTLOCATION\\$DIRNAME");
	create_directory("$RESULTLOCATION\\$DIRNAME\\Build");
	create_directory("$RESULTLOCATION\\$DIRNAME\\Logs");
	create_directory("$RESULTLOCATION\\$DIRNAME\\BuildLogs");
	create_directory("$RESULTLOCATION\\$DIRNAME\\TTL");
	create_directory("$RESULTLOCATION\\$DIRNAME\\Testresults");
	
}

sub read_config_file()
{
	open(MYFILE, "<$CURRENTDIR\\dailybuild.cfg");
	my @data = <MYFILE>;
	close(MYFILE);
	my $line;

	my $DEBUG = 0;
	foreach $line (@data)
	{
		my ($field, $value) = $line =~ m/(.*\=)(.*)$/; 
		print "\n Field = $field" if $DEBUG;
		print "\n Value= $value" if $DEBUG;
		$value =~ s/(^\s*)|(\s*$)//g;

		
		if($field eq "DAILY-BUILD-VIEW-NAME =")
		{
			$DAILYBUILDVIEWNAME = $value;
		}
		elsif($field eq "DAILY-BUILD-LABELED-VIEW-NAME =")
		{
			$DAILYBUILDLABELEDVIEWNAME = $value;
		}
		elsif($field eq "INTEGRATION-BRANCH =")
		{
			$INTGBRANCH = $value;
		}
		elsif($field eq "DUCATI-LABEL =")
		{
			$DUCATILABEL = $value;
		}
		elsif($field eq "OMTB-LABEL =")
		{
			$OMTBLABEL = $value;
		}
		elsif($field eq "FILESYSTEM-PATH =")
		{
			$FSPATH = $value;
		}
		elsif($field eq "LABEL-FORMAT =")
		{
			$LABELFORMAT = $value;
		}
		elsif($field eq "RESULT-LOCATION =")
		{
			$RESULTLOCATION = $value;
		}
		elsif($field eq "INSTALL-DIR =")
		{
			$INSTALLDIR = $value;
		}
		elsif($field eq "BUILD-DEPENDENCY-DIR =")
		{
			$BUILDDEPENDENCYDIR = $value;
		}
		elsif($field eq "XDC-VERSION =")
		{
			$XDCVERSION = $value;
		}
		elsif($field eq "BIOS-VERSION =")
		{
			$BIOSVERSION = $value;
		}
		elsif($field eq "CE-VERSION =")
		{
			$CEVERSION = $value;
		}
		elsif($field eq "FC-VERSION =")
		{
			$FCVERSION = $value;
		}
		elsif($field eq "XDAIS-VERSION =")
		{
			$XDAISVERSION = $value;
		}
		elsif($field eq "OSAL-VERSION =")
		{
			$OSALVERSION = $value;
		}
		elsif($field eq "BRIDGE-PATH =")
		{
			$BRIDGEPATH = $value;
		}
		elsif($field eq "CGTOOLS-VERSION =")
		{
			$CGTOOLSVERSION = $value;
		}
		elsif($field eq "IP-ADDRESS =")
		{
			$IPADDRESS = $value;
		}
		elsif($field eq "OMTB-BUILD-VIEW-NAME =")
		{
			$OMTBBUILDVIEWNAME = $value;
		}
		elsif($field eq "ENABLE-BUILDS =")
		{
			$ENABLEBUILD = $value;
		}
		elsif($field eq "ENABLE-TESTS =")
		{
			$ENABLETEST = $value;
		}
		elsif($field eq "OMTB-BINARY-NAME =")
		{
			$OMTBBINARYNAME = $value;
		}
		elsif($field eq "KERNEL-IMAGE-NAME =")
		{
			$KERNELIMAGENAME = $value;
		}
		elsif($field eq "TEST-MONITOR-INTERVAL =")
		{
			$TESTMONITORINTERVAL = $value;
		}
		elsif($field eq "TEST-MONITOR-MODE =")
		{
			$TESTMONITORMODE = $value;
		}
		elsif($field eq "TEST-EXECUTION-MODE =")
		{
			$TESTEXECUTIONMODE = $value;
		}
		elsif($field eq "COM-PORT =")
		{
			$COMPORT = $value;
		}
		elsif($field eq "RELAY-SWITCH-PATH =")
		{
			$RELAYSWITCHPATH = $value;
		}
		elsif($field eq "FORCE-COPY-OMSFILE =")
		{
			$FORCECOPYOMSFILE = $value;
		}
		elsif($field eq "INCLUDE-COMMON-DECODER-TESTS =")
		{
			$INCLUDECOMMONDECODERTESTS = $value;
		}
		elsif($field eq "UPDATE-CQ-RESULTS =")
		{
			$UPDATECQRESULTS = $value;
		}
		else
		{
			print "\n Unknown field - $field";
			die $!;
		}
	}

}


sub get_hostname()
{
	my $DEBUG = 0;
	my $hostname;
 	open(HOSTNAME, "hostname|");
	$hostname = <HOSTNAME>;
	close(HOSTNAME);
	print $hostname if($DEBUG);

	return $hostname;
}	

sub get_list_of_views()
{
	my $DEBUG = 0;
	my $hostname = get_hostname();

	my $command = "cleartool lsview | findstr -i " . $hostname . "|";
	print $command if($DEBUG);
	print "\n" if($DEBUG);
	open(VIEWS, $command);
	my @views = <VIEWS>;
	close(VIEWS);

	return @views;
}

sub get_clearcase_path()
{
	my $DEBUG = 0;

	my $hostname = get_hostname();
	my @views = get_list_of_views();
	my $view;

	foreach $view (@views)
	{
		print $view if ($DEBUG);
		my($viewname, $path) = $view=~ m/(.*\ )(.*)$/;
		print "\n" if ($DEBUG);
		print $viewname if ($DEBUG);
		print "\n" if ($DEBUG);
		print $path if ($DEBUG);
		print "\n" if ($DEBUG);

		my($cc_path, $view_name) = $path=~ m/(.*\\)(.*)$/;
		print "\n 2:" if ($DEBUG);
		print $cc_path if ($DEBUG);
		print "\n 2:" if ($DEBUG);
		print $view_name if ($DEBUG);
		print "\n" if ($DEBUG);

		#Return after the first instance found
		return $cc_path;
	}

}

sub create_view($)
{
	my $DEBUG = 0;
	my $viewname = shift;

	my $viewpath = get_clearcase_path();
	print $viewpath if($DEBUG);

	my $command = "cleartool mkview -tag $viewname $viewpath\\$viewname.vws";
	system($command);
	print "\n";
}

sub set_configspec_for_view($$)
{
	my $view = shift;
	my $configspec = shift;

	unlink("cs.txt");

	open (MYFILE, '>>cs.txt');
	print MYFILE $configspec;
	close (MYFILE); 

	my $command = "cleartool setcs -tag $view cs.txt";
	system($command);

	#unlink("cs.txt");
}


sub delete_and_create_view($$)
{
	my $DEBUG = 0;
	my $inputview = shift;
	my $configspec = shift;

	my $hostname = get_hostname();
	my @views = get_list_of_views();

	chomp($hostname);
	$inputview = $hostname . "_" . $inputview;
	print "\n View name to delete = $inputview" if $DEBUG;
	my $view;
	foreach $view (@views)
	{
		my($viewname, $path) = $view=~ m/(.*\ )(.*)$/;
		if($viewname =~ m/$inputview/)
		{
			print "\n Proceeding to delete view  - $inputview";
			my $command = "cleartool rmview -tag $inputview";
			system($command);
		}
	}

	create_view($inputview);
	print "\n View  - $inputview has been created";

	set_configspec_for_view($inputview, $configspec);
}

sub find_checkouts($)
{
	my $viewname = shift;
	my $retval = 0;

	my $hostname = get_hostname();
	chomp($hostname);
	$viewname = $hostname . "_" . $viewname;


	#my $command = "cleartool find M:\\$viewname\\WTSD_DucatiMMSW\\ -bra brtype($INTGBRANCH) -print >> tmp.txt";;
	#my $command = "cleartool find M:\\$viewname\\WTSD_DucatiMMSW\\ -element \"version(\.\.\.\/$INTGBRANCH\/LATEST\)\" -print >> tmp.txt";;
	unlink("tmp.txt");
	my $command = "cleartool find M:\\$viewname\\WTSD_DucatiMMSW\\ -version brtype($INTGBRANCH) -print >> tmp.txt";;
	system($command);

	open(MYFILE, "<tmp.txt");
	my @lines = <MYFILE>;
	my $line;
	close(MYFILE);

	open(CHECKOUT, ">>$RESULTLOCATION\\$DIRNAME\\BuildLogs\\checkedoutfiles.txt");
	foreach $line (@lines)
	{
		if($line =~ m/CHECKEDOUT/)
		{
			$retval = 1;
			chomp ($line);
			print "$line is CHECKEDOUT";
			print CHECKOUT $line;

			$line =~ s/CHECKEDOUT/LATEST/g;
			$command = "cleartool lsco $line | findstr $INTGBRANCH";
			my $dummy;
			open($dummy, "$command|");
			print CHECKOUT "\nDetails: \n       ";
			while(<$dummy>)
			{
				print CHECKOUT $_;
			}
			print CHECKOUT "\n";

		}
	}
	close(CHECKOUT);

	unlink("tmp.txt");
	return $retval;
}


sub create_snapshot($$)
{
	my $viewname = shift;
	my $filename = shift;
	my $retval = 0;

	my $hostname = get_hostname();
	chomp($hostname);
	$viewname = $hostname . "_" . $viewname;
	my $command = "cleartool ls -r M:\\$viewname\\WTSD_DucatiMMSW\\ > $RESULTLOCATION\\$DIRNAME\\BuildLogs\\$filename.txt";
	system($command);
}	

sub create_label($$)
{
	my $DEBUG = 0;
	my $label = shift;
	my $viewname = shift;

	my $date = get_current_date();
	$label = "$label-$date";
	print $label;

	my $hostname = get_hostname();
	chomp($hostname);
	$viewname = $hostname . "_" . $viewname;
	my $path = "M:\\$viewname\\WTSD_DucatiMMSW";
	print "\n Path = $path";
	chdir($path);
	system("dir") if $DEBUG;

	my $cmd = "cleartool mklbtype -nc $label";
	system($cmd);
	return $label;
}

sub apply_label($$$)
{
	my $viewname = shift;
	my $branch = shift;
	my $label = shift;

	my $folder_path;
	my $br_name;
	my $label_name;

	my $retval = 0;

	my $hostname = get_hostname();
	chomp($hostname);
	$viewname = $hostname . "_" . $viewname;

	$folder_path="M:\\$viewname\\WTSD_DucatiMMSW";
	$br_name=$branch;
	$label_name=$label;

	my $cmd="cleartool find $folder_path -element \"version(\.\.\.\/$br_name\/LATEST\)\" -print";

	print "\n View name = $folder_path";
	print "\n Branch name = $br_name";
	print "\n Label name = $label_name";
	print "\n Command = $cmd";
	my $DUMMY;



	open ($DUMMY,"$cmd|");

	while(<$DUMMY>){

		s/\.\\//;
		s/\@\@//;
		s/\n//;
		print $_;

		my $pname=$_;

		my $command="cleartool mklabel $label_name $pname";

		my $s=system("$command");


		if($s==256){
			print $s;
			$command="cleartool mklabel \-replace $label_name $pname"; 

			system("$command"); 
		}
	}

	close $DUMMY;
}

sub create_and_apply_label()
{
	my $label = create_label($LABELFORMAT, $DAILYBUILDVIEWNAME);
	print $label;

	apply_label($DAILYBUILDVIEWNAME, $INTGBRANCH, $label);
	return $label;
}

sub get_latest_file_in_dir($)
{
	my $DEBUG = 0;
	my $DIR = shift;
	print "\n $DIR" if $DEBUG;
	my @files = get_list_of_files($DIR);
	print @files if $DEBUG;
	my $modifiedtime = 0;
	my $retfile;
	my $sort_file;
	my $st;
	foreach $sort_file (@files)
	{
		print "\n sort file = $sort_file - " , (stat($sort_file))[9] if $DEBUG;
		$st = stat($sort_file);
		print "\n Stat - ", $st->mtime if $DEBUG;
		if($st->mtime > $modifiedtime)
		{
			$retfile = $sort_file;
		}
	}

	return $retfile;


}

sub pushfiles()
{
    push @FILES, $File::Find::name if(-f); # modify the regex as per your needs or pass it as another arg
}

sub get_list_of_files($)
{
	my $DEBUG = 0;
	my $path = shift;
	@FILES = ();
	print "\n" if $DEBUG;
	print $path, "- In get_list_of file\n" if $DEBUG;
	find(\&pushfiles,"$path");
	print "\n Files = @FILES" if $DEBUG;
	return @FILES;
}

sub get_filesize_of_latest_file_in_directory($)
{
	my $DEBUG = 0;
	my $dir = shift;
	my $latestlogfile = get_latest_file_in_dir($dir);
	print "\n Returned file -", $latestlogfile, "\n" if $DEBUG;
	my $st = stat($latestlogfile);
	print "\n Size - ", $st->size if $DEBUG;
	return $st->size;
}


sub create_build_settings_and_build_ducati($)
{
	my $viewname = shift;

	my $hostname = get_hostname();
	chomp($hostname);
	$viewname = $hostname . "_" . $viewname;
	
	my $path = "M:\\$viewname\\WTSD_DucatiMMSW";
	print "\n Path = $path";
	chdir($path);

	generate_ducati_batch_file($path);

	$path = "M:\\$viewname\\WTSD_DucatiMMSW\\platform\\base_image";
	print "\n Path = $path";
	chdir($path);
	build_ducati();
}
	

sub find_executable_containing($$)
{
	my $filter = shift;
	my $location = shift;

	print "$filter \n";
	print "$location \n";

	opendir (DIR, $location)
		or die "Unable to open $location: $!";

	my @files = grep { !/^\.{1,2}$/ } readdir(DIR);

	closedir(DIR);

	my $file;
	foreach $file (@files)
	{
		if($file =~ m/($filter)/)
		{
			return $file;
		}
	}

	print "\n Filename containing $filter not found: $!";
	return;
}

sub generate_ducati_batch_file($)
{
	my $ducati_path = shift;

	open (MYFILE, '>ducati_build_settings.bat');

	#set XDCPATH=E:\Build_requirements_February\Ducati-16\Bridge\ipc;C:\Program Files\Texas Instruments\bios_6_20_03_44_eng\packages;E:\Build_requirements_October\codec_engine_3_00_00_26\packages;E:\Build_requirements_October\framework_components_3_00_00_50_eng\packages;E:\Build_requirements_October\xdais_7_00_00_20_eng\packages;E:\Build_requirements_October\osal_1_00_00_38\packages;..\..\framework;Z:\WTSD_DucatiMMSW\ext_rel\ivahd_codecs\packages;
	my $line = "$BRIDGEPATH;";
	my $dir = find_executable_containing($BIOSVERSION, $INSTALLDIR);
	$line = $line . "$INSTALLDIR\\" . $dir . "\\packages;";
	$dir = find_executable_containing($CEVERSION, $BUILDDEPENDENCYDIR);
	$line = $line . "$BUILDDEPENDENCYDIR\\" . $dir . "\\packages;";
	$dir = find_executable_containing($FCVERSION, $BUILDDEPENDENCYDIR);
	$line = $line . "$BUILDDEPENDENCYDIR\\" . $dir . "\\packages;";
	$dir = find_executable_containing($XDAISVERSION, $BUILDDEPENDENCYDIR);
	$line = $line . "$BUILDDEPENDENCYDIR\\" . $dir . "\\packages;";
	$dir = find_executable_containing($OSALVERSION, $BUILDDEPENDENCYDIR);
	$line = $line . "$BUILDDEPENDENCYDIR\\" . $dir . "\\packages;";
	$line = $line . "..\\..\\framework;";
	$line = $line . $ducati_path . "\\ext_rel\\ivahd_codecs\\packages;";

	$ENV{'XDCPATH'} = "$line";
	$line = "\n set XDCPATH=$line";
	print MYFILE $line;

	#set TMS470CGTOOLPATH=C:/Program Files/Texas Instruments/TMS470 Code Generation Tools 4.6.0;
	my $dirname = find_executable_containing($CGTOOLSVERSION, $INSTALLDIR);
	$ENV{'TMS470CGTOOLPATH'}="$INSTALLDIR\\$dirname;";
	print MYFILE "\nset TMS470CGTOOLPATH=$INSTALLDIR\\$dirname;";

	#set XDCROOT=C:/Program Files/Texas Instruments/xdctools_3_15_03_67;
	$dirname = find_executable_containing($XDCVERSION, $INSTALLDIR);
	$ENV{'XDCROOT'}="$INSTALLDIR\\$dirname;";
	print MYFILE "\nset XDCROOT=$INSTALLDIR\\$dirname;";
	$ENV{'PATH'}="$ENV{'PATH'};$INSTALLDIR\\$dirname;";
	print MYFILE "\nset Path=%Path%;%XDCROOT%";
	$ENV{'XDCBUILDCFG'}="../../build/config.bld";
	print MYFILE "\nset XDCBUILDCFG=../../build/config.bld";
	#$ENV{'XDCARGS'}="profile=release core=app_m3 target_build=BUILD_OMAP4 cache_wa=NEWWA";
	#print MYFILE "\nset XDCARGS=profile=release core=app_m3 target_build=BUILD_OMAP4 cache_wa=NEWWA";
	$ENV{'XDCARGS'}="profile=release core=app_m3 target_build=BUILD_OMAP4";
	print MYFILE "\nset XDCARGS=profile=release core=app_m3 target_build=BUILD_OMAP4";
	close (MYFILE); 

}


sub build_ducati()
{
	my $DEBUG = 0;
	#print "$ENV{'XDCBUILDCFG'}";
	#system('cd');
	my $command = "xdc --jobs=9 -PD .";
	print $command if ($DEBUG);
	system($command);
}


sub copy_build_to_filesystem()
{
	my $copypath = $FSPATH; 
	$copypath =~ s/\//\\/g;
	my $command = "copy $RESULTLOCATION\\$DIRNAME\\Build\\*.xem3 \\\\blrsamba$copypath\\ducati\\.";
	print "\n";
	print $command;
	system($command);
}

sub setup_ttl()
{
	my $DEBUG = 0;
	my $fs_rel_path = $FSPATH;
	my ($ignore, $user, $fs) = $fs_rel_path =~ m/(.*\/)(.*\/)(.*)$/; 
	print "\nIgnore = $ignore" if $DEBUG;
	print "\nUser = $user" if $DEBUG;
	print "\nFS = $fs" if $DEBUG;
	chop($user);
	print "\n Generating TTL" if $DEBUG;
	open (MYFILE, ">$RESULTLOCATION\\$DIRNAME\\TTL\\ducati_boot_script.ttl");
	print MYFILE"\n	connect '/C=$COMPORT'"; 

	print MYFILE "\n ; get user name";
	print MYFILE "\n	getenv 'USERNAME' username";
	print MYFILE "\n	; get the date and time";
	print MYFILE "\n	gettime timestr \"%Y%m%d-%H%M%S\"";

	print MYFILE "\n	; add the user name and the timestamp to the log file name";
	print MYFILE "\n	sprintf2 filename 'console_%s_%s.log' username timestr";

	print MYFILE "\n	; change the current directory";
	print MYFILE "\n	changedir '$RESULTLOCATION\\$DIRNAME\\Logs'";

	print MYFILE "\n	logopen filename 0 0 0 0 0";
	print MYFILE "\n	logwrite 'Log start'#13#10";
	print MYFILE "\n	logwrite '*****************************************************'#13#10";

	print MYFILE"\n	sendln";
	print MYFILE"\n	wait 'OMAP44XX SDP #'";
	print MYFILE"\n	sendln 'mmcinit 0'";
	print MYFILE"\n	wait 'OMAP44XX SDP #'";
	print MYFILE"\n	sendln 'fatload mmc 0 80200000  $KERNELIMAGENAME'";
	print MYFILE"\n	wait 'OMAP44XX SDP #'";
	print MYFILE"\n pause 1";
	#print MYFILE"\n	sendln 'setenv bootargs mem=463M console=ttyO2 consoleblank=0,115200n8 noinitrd root=/dev/nfs rw nfsroot=172.24.194.61:/vol/vol4/cssd_omap_ducati/$user/$fs/, tcp,rsize=4096,wsize=4096 nolock,tcp ip=$IPADDRESS:172.24.194.61:172.24.188.1:255.255.252.0'";
	#print MYFILE"\n	sendln 'setenv bootargs mem=463M console=ttyO2,115200n8 noinitrd root=/dev/nfs rw nfsroot=172.24.194.61:/vol/vol4/cssd_omap_ducati/$user/$fs/, tcp,rsize=4096,wsize=4096 nolock,tcp ip=$IPADDRESS:172.24.194.61:172.24.188.1:255.255.252.0 consoleblank=0'";
	print MYFILE"\n	sendln 'setenv bootargs mem=463M console=ttyO2,115200n8 noinitrd root=/dev/nfs rw nfsroot=172.24.194.61:/vol/vol4/cssd_omap_ducati/$user/$fs/, tcp,rsize=4096,wsize=4096 nolock,tcp ip=$IPADDRESS consoleblank=0'";
	print MYFILE"\n pause 1";
	print MYFILE"\n	wait 'OMAP44XX SDP #'";
	print MYFILE"\n pause 1";
	print MYFILE"\n	sendln 'bootm 80200000'";
        print MYFILE"\n	wait 'Please press Enter to activate this console.'";
	print MYFILE"\n	sendln ";
	print MYFILE"\n	sendln ";
	print MYFILE"\n	wait '#'";
	print MYFILE"\n	sendln ";
	print MYFILE"\n	sendln 'cd ducati/'";
	print MYFILE"\n	wait '#'";
	#print MYFILE"\n	sendln './disableblanking.sh &'";
	#print MYFILE"\n	wait '#'";
	print MYFILE"\n	sendln '/bin/syslink_trace_daemon.out'";
	print MYFILE"\n	wait '#'";
	print MYFILE"\nsendln '/bin/syslink_daemon.out /ducati/Notify_MPUSYS_reroute_Test_Core0.xem3 /ducati/base_image_app_m3.xem3'";
	print MYFILE"\n	wait '#'";
	print MYFILE"\n	wait 'Ready to receive requests from Ducati'";
	print MYFILE"\n pause 5";
	print MYFILE "\n sendln";
	print MYFILE"\n	wait '#'";

	my @lines = get_list_of_files("$RESULTLOCATION\\$DIRNAME\\TTL");
	my $line;
	foreach $line (@lines)
	{
		print $line , "\n" if $DEBUG;
		$line =~ s/\//\\/g;
		if($line =~ m/component-/)
		{
			my ($ignore, $required) = $line =~ m/(.*TTL\\)(.*)$/;
			if($line =~ m/~/ or $line =~ m/swp/)
			{
				#Ignore as there are vim generated files
			}
			else
			{
				print MYFILE "\ninclude '$required'";
			}
		}
	}
	close(MYFILE);
}

sub setup_tests($$$@)
{
	my $DEBUG = 0;
	my $componentname = shift;
	my $component_script_location = shift;
	my $input_file_location = shift;
	my $waitforstring = shift;
	my @extnlist = @_;

	my $ttl_script_location = "$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname";
	my $destination_location = "\\\\blrsamba$FSPATH/ducati/$componentname";
	$destination_location =~ s/\//\\/g;


	prepare_file_list_report($component_script_location, $input_file_location, "$componentname");

	print "\n Proceeding to generate TTL script for $componentname";
	print "\n Script Location = $component_script_location";
	chdir($component_script_location);
	system("dir");

	print "\n Input file location = $input_file_location";
	system("dir $input_file_location");

	#system("rmdir/s/q $destination_location");
	print "\n Folder name = $destination_location";
	system("mkdir $destination_location");
	print "\n The directory has been created";
	system("mkdir $destination_location\\config");
	system("mkdir $destination_location\\input");
	system("mkdir $destination_location\\output");

	system("mkdir $RESULTLOCATION\\$DIRNAME\\TTL\\$componentname");
	system("mkdir $RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\omx-componentttl");

	my @files = get_list_of_files($input_file_location);
	my $temp;
	my $extnitem;
	foreach $temp (@files)
	{
		foreach $extnitem (@extnlist)
		{
			if($temp =~ m/$extnitem$/)
			{
				$temp =~ s/\//\\/g;
				print "\n $temp" if $DEBUG;
				my ($dir, $outfilename, $extension) = $temp =~ m/(.*\\)(.*\.)(.*)$/; 
				print "\n Filename - $destination_location\\input\\$outfilename$extension " if $DEBUG;

				if(-e "$destination_location\\input\\$outfilename$extension")
				{
					print "\n File $destination_location\\input\\$outfilename$extension already exists" if $DEBUG;
				}
				else
				{
					print "\n Proceeding to copy file - $temp";
					my $command = "copy \"$temp\" \"$destination_location\\input\"";
					system($command);
				}
			}
		}
	}

	#Copy the input cfg files
	@files = get_list_of_files($component_script_location);
	foreach $temp (@files)
	{
		if($temp =~ m/cfg$/)
		{
			print "\n $temp" if $DEBUG;
			$temp =~ s/\//\\/g;

			my ($dir, $outfilename, $extension) = $temp =~ m/(.*\\)(.*\.)(.*)$/; 
			print "\n Filename - $destination_location\\config\\$outfilename$extension " if $DEBUG;

			if(-e "$destination_location\\config\\$outfilename$extension")
			{
				print "\n File $destination_location\\config\\$outfilename$extension already exists" if $DEBUG;
			}
			else
			{
				print "\n Proceeding to copy file - $temp";
				my $command = "copy $temp $destination_location\\config";
				system($command);
			}

		}
	}

	#Copy the oms and generate TTL files
	@files = get_list_of_files($component_script_location);
	foreach $temp (@files)
	{
		if($temp =~ m/oms$/)
		{
			print "\n $temp" if $DEBUG;
			$temp =~ s/\//\\/g;

			my ($dir, $outfilename, $extension) = $temp =~ m/(.*\\)(.*\.)(.*)$/; 
			print "\n Filename - $destination_location\\$outfilename$extension " if $DEBUG;

			#Copying OMS Files
			if($FORCECOPYOMSFILE ne "YES")
			{
				if(-e "$destination_location\\$outfilename$extension")
				{
					print "\n File $destination_location\\$outfilename$extension already exists" if $DEBUG;
				}
				else
				{
					print "\n Proceeding to copy file - $temp";
					my $command = "copy $temp $destination_location";
					system($command);
				}
			}
			else
			{
				print "\n Proceeding to copy file - $temp";
				my $command = "copy $temp $destination_location";
				system($command);
			}

			generate_ttl($temp,"$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname", 4000, $waitforstring);
		}
	}

	if($INCLUDECOMMONDECODERTESTS eq "YES")
	{
		if($componentname eq "vc1decoder" or $componentname eq "mpeg4decoder" or $componentname eq "h264decoder" or $componentname eq "vp6decoder" or $componentname eq "vp7decoder")
		{
			#Copy the input ttl files from common decoder folder
			$component_script_location = "$component_script_location\\..\\commonvideodecoder";
			@files = get_list_of_files($component_script_location);
			foreach $temp (@files)
			{
				if($temp =~ m/ttl$/)
				{
					print "\n Files = $temp"; #if $DEBUG;
					$temp =~ s/\//\\/g;

					my ($dir, $outfilename, $extension) = $temp =~ m/(.*\\)(.*\.)(.*)$/; 
					print "\n Filename - $RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\ " if $DEBUG;

					print "\n Outfilename = $outfilename";
					my $replacestring;
					if($componentname eq "vc1decoder")
					{
						$replacestring = "TC_VIDDEC_OMX_VC1D_";
					}
					if($componentname eq "mpeg4decoder")
					{
						$replacestring = "TC_VIDDEC_OMX_MPEG4D_";
					}
					if($componentname eq "h264decoder")
					{
						$replacestring = "TC_VIDDEC_OMX_H264D_";
					}
					if($componentname eq "vp6decoder")
					{
						$replacestring = "TC_VIDDEC_OMX_VP6D_";
					}
					if($componentname eq "vp7decoder")
					{
						$replacestring = "TC_VIDDEC_OMX_VP7D_";
					}
					$outfilename = extractandappend("$outfilename", "TC_VIDDEC_OMX_", "$replacestring");
					print "\n New Outfilename = $outfilename";

					if(-e "$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\omx-componentttl\\$outfilename$extension")
					{
						print "\n File $RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\omx-componentttl\\$outfilename$extension already exists" if $DEBUG;
					}
					else
					{
						print "\n Proceeding to copy file - $temp";
						my $retval = parse_ttl($temp);
						if($retval)
						{
							my $command = "copy $temp $RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\omx-componentttl\\$outfilename$extension";
							system($command);
							generate_ttl_for_api_test($componentname, "$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\omx-componentttl\\$outfilename$extension", "$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname");
						}
						else
						{
							print "\n Ignored the copy of TTL file - $temp";
						}
					}

				}
			}
		}
	}

	#process_ttl("$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname\\", $componentname);

	generate_component_ttl("$componentname", "component-$componentname.ttl", "$RESULTLOCATION\\$DIRNAME\\TTL\\$componentname");
}

sub extractandappend($$$)
{
        my $extractstring = shift;
        my $pattern = shift;
        my $appendstring = shift;
        my $temp;

        my ($firstpart, $temp)= split(/$pattern/, $extractstring);
        print "\n $temp";

        my $ret = $appendstring . $temp;
        return $ret;
}



sub parse_ttl($)
{
	my $path = shift;
	my $line;
	my $DEBUG = 1;

	print "\n The file path is $path" if $DEBUG;
	open(MYFILE, "$path") or die $!;
	my @lines = <MYFILE>;
	close(MYFILE);

	foreach $line (@lines)
	{
		if($line =~ m/(.*)Common Decoder$/)
		{
			print "\n File can be used" if $DEBUG;
			return 1;
		}
	}

	return 0;
}




sub setup_tests_generate_ttl()
{
	my $DEBUG = 1;
	my $hostname = get_hostname();
	chomp($hostname);
	my $viewname = $hostname . "_" . $OMTBBUILDVIEWNAME;
	my $OMTBSCRIPTLOCATION = "omtb\\source_code\\omtb\\packages\\ti\\sdo\\omtb\\omap4430\\scripts";

	open(TESTCONFIG, "$CURRENTDIR\\dailybuild-testconfig.cfg");
	my @testcfg = <TESTCONFIG>;
	close(TESTCONFIG);

	my $line;
	foreach $line (@testcfg)
	{
		my ($field, $value) = $line =~ m/(.*\=)(.*)$/; 
		chop($field);
		print "\n Field = $field" if $DEBUG;
		print "\n Value = $value" if $DEBUG;
		$field =~ s/(^\s*)|(\s*$)//g;
		$value =~ s/(^\s*)|(\s*$)//g;

		if("H264-ENCODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\h264e\\";
			my $input_file_location = "\\\\a0393876pc\\Encoder_input_teststreams\\OMTB_testing";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VENC_FuncTsk";
			my @extn_list = ("yuv");

			setup_tests("h264encoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("H264-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\h264d\\";
			my $input_file_location = "\\\\a0876364pc\\Arbeit\\Testing\\Streams";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VDEC_FuncTsk";
			my @extn_list = ("264", "txt");

			setup_tests("h264decoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("VP6-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\vp6d\\";
			my $input_file_location = "\\\\a0393906pc\\temp\\vp6-vp7-teststreams";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VDEC_FuncTsk";
			my @extn_list = ("vp6", "txt");

			setup_tests("vp6decoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("VP7-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\vp7d\\";
			my $input_file_location = "\\\\a0393906pc\\temp\\vp6-vp7-teststreams";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VDEC_FuncTsk";
			my @extn_list = ("vp7", "txt");

			setup_tests("vp7decoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("VC1-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\vc1d\\";
			#my $script_location = "\\\\a0393906pc\\temp\\sudhir";
			my $input_file_location = "\\\\a0393906pc\\temp\\sudhir";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VDEC_FuncTsk";
			my @extn_list = ("vc1", "rcv", "txt", "bits", "264");

			setup_tests("vc1decoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("MPEG4-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\mpeg4d\\";
			my $input_file_location = "\\\\a0393906pc\\temp\\sarthak\\test-vectors\\input";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <H264VDEC_FuncTsk";
			my @extn_list = ("m4v", "bits", "mpeg4", "txt");

			setup_tests("mpeg4decoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("MPEG4-ENCODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\mpeg4e\\";
			my $input_file_location = "\\\\blrsamba\\db\\omapsw_linux1\\brijesh\\fs\\vidbinaries\\input";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <MPEG4VENC_FuncTsk";
			my @extn_list = ("yuv");

			setup_tests("mpeg4encoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
		if("CAMERA-TEST" eq "$field" and $value eq "YES")
		{
			my $OMTBSCRIPTLOCATION = "E:\\cameracfg";
			print "\n Proceeding to generate TTL script for Camera ";

			my $script_location = $OMTBSCRIPTLOCATION;
			#my $input_file_location;
			my $destination_folder = "\\\\blrsamba$FSPATH/ducati";
			$destination_folder =~ s/\//\\/g;

			print "\n Script Location = $script_location";
			chdir($script_location);
			system("dir");

			#print "\n Input file location = $input_file_location";
			#system("dir $input_file_location");

			system("rmdir/s/q $destination_folder\\camera");
			print "\n The directory has been removed";
			print "\n Folder name = $destination_folder\\camera";
			system("mkdir $destination_folder\\camera");
			print "\n The directory has been created";
			system("mkdir $destination_folder\\camera\\config");
			system("mkdir $destination_folder\\camera\\input");
			system("mkdir $destination_folder\\camera\\output");

			my $command ="mkdir \\\\blrsamba$FSPATH\\mmc\\";
			$command =~ s/\//\\/g;
			print $command;
			system($command);

			$command ="mkdir \\\\blrsamba$FSPATH\\mmc\\files";
			$command =~ s/\//\\/g;
			print $command;
			system($command);

			system("mkdir $RESULTLOCATION\\$DIRNAME\\TTL\\Camera");

			print "\n Script location = $script_location  \n";
			#Copy the cfg files
			my @files = get_list_of_files($script_location);
			my $temp;
			foreach $temp (@files)
			{
				if($temp =~ m/cfg$/)
				{
					print "\n $temp";
					$temp =~ s/\//\\/g;
					my $command = "copy $temp $destination_folder\\camera\\config";
					system($command);
				}
			}

			generate_oms_files_for_mpeg4encoder($script_location, "camera");

			#Copy the oms and generate TTL files
			@files = get_list_of_files($script_location);
			#$hack = 1;
			foreach $temp (@files)
			{
				if($temp =~ m/oms$/)
				{
					print "\n $temp";
					$temp =~ s/\//\\/g;
					my $command = "copy $temp $destination_folder\\camera";
					system($command);

					#if($hack == 1)
					#{
					generate_ttl($temp,"$RESULTLOCATION\\$DIRNAME\\TTL\\Camera", 0, "OMTB-CAMERA_FuncTsk: CAMERA FUNC Delete");
					#}
					#$hack++;
				}
			}

			generate_component_ttl("camera","component-camera.ttl", "$RESULTLOCATION\\$DIRNAME\\TTL\\Camera");

		}
		if("JPEG-DECODER-TEST" eq "$field" and $value eq "YES")
		{
			my $script_location = "M:\\$viewname\\$OMTBSCRIPTLOCATION\\jpegd\\";
			my $input_file_location = "\\\\blrsamba\\proj\\omapts\\ducati\\test_patterns\\JPEG Decoder";
			my $wait_for_string = "OMTB-Leaving <Thread , instance #> : <JPEGDEC_FuncTsk";
			my @extn_list = ("jpg", "JPG");

			setup_tests("jpegdecoder", $script_location, $input_file_location, $wait_for_string, @extn_list);
		}
	}


	

}

sub generate_oms_files_for_mpeg4encoder($$)
{
	my $path = shift;
	my $component = shift;

	my @files = get_list_of_files($path);
	my $temp;
	foreach $temp (@files)
	{
		if($temp =~ m/dyn/)
		{
			#Do nothing
		}
		else
		{
			my ($ignore, $cfgfilename) = $temp =~ m/(.*\/)(.*)$/;
			print "\n CFG file name $cfgfilename";
			my $omsfilename = $cfgfilename;
			$omsfilename =~ s/cfg/oms/g;
			print "\n OMS file name $omsfilename";
			open (MYFILE, ">$path\\$omsfilename");
			print MYFILE "\nomx load 0 ./config/$cfgfilename";
			if($component eq "mpeg4enc")
			{
				print MYFILE "\nomx func videnc mpeg4venc 0 0";
			}
			else
			{
				print MYFILE "\nomx func io camera 0 0";
			}
			close(MYFILE);
		}
	}
}

sub generate_component_ttl($$$)
{
	my $path = shift;
	my $ttlfile = shift;
	my $includepath = shift;

	my $DEBUG = 0;

	print "\n Inside generate_component_ttl " if $DEBUG;
	print "\n Result location = $RESULTLOCATION\\$DIRNAME\\TTL\\$ttlfile" if $DEBUG;
	open (MYFILE, ">$RESULTLOCATION\\$DIRNAME\\TTL\\$ttlfile");
	print MYFILE "\nsendln 'cd $path'";
	print MYFILE "\nsendln 'echo \"1\" > /sys/devices/platform/omapdss/display1/enabled'";
	print MYFILE "\npause 2";
	print MYFILE "\nsendln 'echo \"0\" > /sys/devices/platform/omapdss/overlay3/enabled'";
	print MYFILE "\npause 2";
	print MYFILE "\nsendln 'echo \"2lcd\" > /sys/devices/platform/omapdss/overlay3/manager'";
	print MYFILE "\npause 2";
	print MYFILE "\nsendln 'echo \"1\" > /sys/devices/platform/omapdss/overlay3/enabled'";
	print MYFILE "\npause 2";
	if($TESTEXECUTIONMODE ne "exit-every-run")
	{
		print MYFILE "\nsendln '../$OMTBBINARYNAME'";
		print MYFILE "\nwait 'OMTB>'";
		#print MYFILE "\nsendln 'omx store 0 cfg0.cfg'";
		#print MYFILE "\nwait 'OMTB>'";	
		#print MYFILE "\nsendln 'omx store 1 cfg1.cfg'";
		#print MYFILE "\nwait 'OMTB>'";	
	}
	my @lines = get_list_of_files($includepath);
	my $line;
	foreach $line (@lines)
	{
		if($line =~ m/ttl$/ and !($line =~ m/omx-componentttl/))
		{
			my ($ignore, $required) = $line =~ m/(.*TTL\\)(.*)$/;
			my $test = check_ignore_test($required, $path);
			print "\n Return value = $test" if $DEBUG;
			if($test eq "ignore")
			{
				print MYFILE "\n;include '$required'";
			}
			else
			{
				print MYFILE "\ninclude '$required'";
			}
		}
	}
	if($TESTEXECUTIONMODE ne "exit-every-run")
	{
		print MYFILE "\nsendln 'exit'";
	}
	print MYFILE "\nsendln 'cd ..'";
	close(MYFILE);
}

sub check_ignore_test($$)
{
	my $DEBUG = 0;
	my $testname = shift;
	my $componentname = shift;
	my $retval = "";
	
	print "\n Testname = $testname" if $DEBUG;
	print "\n Component Name = $componentname" if $DEBUG;
	#system("dir");

	if(-e "$CURRENTDIR\\$componentname-ignore.txt")
	{
		open(IGNOREFILE, "$CURRENTDIR\\$componentname-ignore.txt");
		my @lines = <IGNOREFILE>;
		close(IGNOREFILE);

		my $line;
		foreach $line (@lines)
		{
			chomp($line);
			print "\n Line in function  $line" if $DEBUG;
			print "\n Test name $testname" if $DEBUG;
			#if($testname =~ m/$line/)
			my ($folder, $test, $extn) = $testname =~ m/(.*\/)(.*\.)(.*)$/;
			chop($test);
			print "\n Testname = $test" if $DEBUG;
			if($test eq $line)
			{
				print "\n Ignore testcase - $test" if $DEBUG;
				$retval = "ignore";	
				return $retval;
			}
		}
		

	}
	else
	{
		print "\n No user configured tests to ignore" if $DEBUG;
	}


	if(-e "$CURRENTDIR\\$componentname-autogen-ignore.txt")
	{
		open(IGNOREFILE, "$CURRENTDIR\\$componentname-autogen-ignore.txt");
		my @lines = <IGNOREFILE>;
		close(IGNOREFILE);

		my $line;
		foreach $line (@lines)
		{
			chomp($line);
			print "\n Line in function  $line" if $DEBUG;
			print "\n Test name $testname" if $DEBUG;
			#if($testname =~ m/$line/)
			my ($folder, $test, $extn) = $testname =~ m/(.*\/)(.*\.)(.*)$/;
			chop($test);
			print "\n Testname = $test" if $DEBUG;
			if($test eq $line)
			{
				print "\n Ignore testcase - $test" if $DEBUG;
				$retval = "ignore";	
				return $retval;
			}
		}
		

	}
	else
	{
		print "\n No Autogenerated tests to ignore" if $DEBUG;
	}

	return $retval;
}


sub parseomsfile($)
{
	my $DEBUG = 0;
	my $filepath = shift;
	my $retval = "none";

	open(OMSFILE, $filepath);
	my @lines = <OMSFILE>;
	close(OMSFILE);

	my $line;
	foreach $line (@lines)
	{
		if($line =~ m/api_test/)
		{
			print "\n apitest" if $DEBUG;
			$retval = "apitest";	
			return $retval;
		}
		if($line =~ m/api\ / and $retval ne "func")
		{
			print "\n api mode" if $DEBUG;
			$retval = "apimode";	
		}
		if($line =~ m/func/)
		{
			print "\n func" if $DEBUG;
			$retval = "func";	
			return $retval;
		}

	}
	print "\n Retval = none" if $DEBUG;
	return $retval;
}


sub generate_ttl($$$)
{
	my $DEBUG = 0;
	my $omsfile = shift;
	my $outpath = shift;
	my $timeout = shift;
	my $waitstring = shift;
	print "OMS FILE name = $omsfile" if $DEBUG;
	print "Output Path = $outpath" if $DEBUG;

	my $retval = parseomsfile($omsfile);
	if($retval eq "apitest" or $retval eq "apimode" or $retval eq "none")
	#if($retval eq "apitest" or $retval eq "func")
	#if($retval eq "apimode" or $retval eq "func")
	#if($retval eq "func")
	{
		return;
	}

	my ($dir, $outfilename, $extension) = $omsfile =~ m/(.*\\)(.*\.)(.*)$/; 
	print "\n Dir = $dir" if $DEBUG;
	print "\n Filename = $outfilename" if $DEBUG;
	print "\n extension = $extension" if $DEBUG;
	chop($outfilename);

	my $testid = $outfilename;
	$outfilename = $outfilename . ".ttl";
	my $outfilepath = "$outpath\\$outfilename";
	print "\n TTL Filename = $outfilename" if $DEBUG;

	open(TTLFILE, ">$outfilepath");

	print TTLFILE "\ngetdir previousdirectory";
	print TTLFILE "\ntimeout = $timeout";
	print TTLFILE "\nsetdir '$RESULTLOCATION\\$DIRNAME\\Testresults'";
	print TTLFILE "\nTestCaseID = '$testid,'";

	print TTLFILE "\ngettime startime \"%H:%M:%S,\"";
	print TTLFILE "\ngettime date \"%Y-%m-%d\"";
	if($TESTEXECUTIONMODE eq "exit-every-run")
	{
		print TTLFILE "\nsendln";
		print TTLFILE "\nwait '#'";
		print TTLFILE "\nsendln '../$OMTBBINARYNAME'";
		print TTLFILE "\nwait 'OMTB>'";
	}
	else
	{
		print TTLFILE "\nsendln";
		print TTLFILE "\nwait 'OMTB>'";
	}
	print TTLFILE "\ntitle=\"Test status: Executing\"";
	print TTLFILE "\nmessage=\"Testcase ID: $testid\"";
	print TTLFILE "\nstatusbox message title";
	#print TTLFILE "\nsendln 'omx load 0 cfg0.cfg'";
	#print TTLFILE "\nwait 'sampcomp outbuftype OMTB_1D_1BUFFER'";
	#print TTLFILE "\nsendln 'omx load 1 cfg1.cfg'";
	#print TTLFILE "\nwait 'sampcomp outbuftype OMTB_1D_1BUFFER'";
	#print TTLFILE "\nsendln 'omx omtb_dbg_lvl 0x0'";
	#print TTLFILE "\nwait 'OMTB>'";
	#print TTLFILE "\nsendln 'omx setp 0 vdec outdata_mode v4l2'";
	#print TTLFILE "\nwait 'OMTB>'";
	print TTLFILE "\nsendln 'omx api init'";
	print TTLFILE "\nwait 'OMTB>'";
	print TTLFILE "\nsendln 'omx -s $testid.oms'";
	if($retval eq "func")
	{
		print TTLFILE "\nwait '$waitstring'";
	}
	else
	{
		print TTLFILE "\nwait 'OMS-OK'";
	}
	print TTLFILE "\nclosesbox";
	print TTLFILE "\nsendln 'omx api uninit'";
	print TTLFILE "\nwait 'OMTB>'";
	if($TESTEXECUTIONMODE eq "exit-every-run")
	{
		print TTLFILE "\nsendln 'exit'";
		print TTLFILE "\nwait 'OMTB-OMTB application Finished'";
	}
	print TTLFILE "\nif result = 0 goto error";
	print TTLFILE "\nsendln";
	print TTLFILE "\ngettime endtime \"%H:%M:%S,\"";
	print TTLFILE "\nstrconcat TestCaseID 'P,'";
	print TTLFILE "\nstrconcat TestCaseID startime";
	print TTLFILE "\nstrconcat TestCaseID endtime";
	print TTLFILE "\nstrconcat TestCaseID date";

	print TTLFILE "\n       call updatefile";
	print TTLFILE "\nexit";

	print TTLFILE "\n:updatefile";
	print TTLFILE "\n	fileopen fhandle 'testresults.csv' 1";
	print TTLFILE "\n	filewriteln fhandle TestcaseID";
	print TTLFILE "\n	fileclose fhandle";
	print TTLFILE "\n	call restorepreviousdirectory";
	print TTLFILE "\npause 2";
	print TTLFILE "\n	return";

	print TTLFILE "\n:error";
	print TTLFILE "\n	fileopen fhandle 'testresults.csv' 1";
	print TTLFILE "\n	temp = TestCaseID";
	print TTLFILE "\n	gettime endtime \"%H:%M:%S,\"";
	print TTLFILE "\n	strconcat temp 'F,'";
	print TTLFILE "\n	strconcat temp startime";
	print TTLFILE "\n	strconcat temp endtime";
	print TTLFILE "\n	strconcat temp date";
	print TTLFILE "\n	filewriteln fhandle temp";
	print TTLFILE "\n	fileclose fhandle";
	print TTLFILE "\n	sendln 'Testcase failed'";
	print TTLFILE "\n	call restorepreviousdirectory";
	print TTLFILE "\n	exit";
	print TTLFILE "\n:restorepreviousdirectory";
	print TTLFILE "\nsetdir previousdirectory";
	print TTLFILE "\npause 2";
	print TTLFILE "\nreturn";
	close(TTLFILE);
}


sub generate_ttl_for_api_test($$)
{
	my $DEBUG = 1;
	my $componentname = shift;
	my $ttlfile = shift;
	my $outpath = shift;
	my $timeout = 250;
	print "TTL FILE name = $ttlfile" if $DEBUG;
	print "Output Path = $outpath" if $DEBUG;

	my ($dir, $outfilename, $extension) = $ttlfile =~ m/(.*\\)(.*\.)(.*)$/; 
	print "\n Dir = $dir" if $DEBUG;
	print "\n Filename = $outfilename" if $DEBUG;
	print "\n extension = $extension" if $DEBUG;
	chop($outfilename);

	my $testid = $outfilename;
	$outfilename = $outfilename . ".ttl";
	my $outfilepath = "$outpath\\$outfilename";
	print "\n TTL Filename = $outfilename" if $DEBUG;

	open(TTLFILE, ">$outfilepath");

	print TTLFILE "\ngetdir previousdirectory";
	print TTLFILE "\ntimeout = $timeout";
	print TTLFILE "\nTestCaseID = '$testid,'";

	print TTLFILE "\ngettime startime \"%H:%M:%S,\"";
	print TTLFILE "\ngettime date \"%Y-%m-%d\"";
	if($TESTEXECUTIONMODE eq "exit-every-run")
	{
		print TTLFILE "\nsendln";
		print TTLFILE "\nwait '#'";
		print TTLFILE "\nsendln '../$OMTBBINARYNAME'";
		print TTLFILE "\nwait 'OMTB>'";
	}
	else
	{
		print TTLFILE "\nsendln";
		print TTLFILE "\nwait 'OMTB>'";
	}
	print TTLFILE "\nsendln 'Currently executing - $testid'";
	print TTLFILE "\ntitle=\"Test status: Executing\"";
	print TTLFILE "\nmessage=\"Testcase ID: $testid\"";
	print TTLFILE "\nstatusbox message title";
	print TTLFILE "\ninclude './$componentname/omx-componentttl/$testid.ttl'";
	if($TESTEXECUTIONMODE eq "exit-every-run")
	{
		print TTLFILE "\nsendln 'exit'";
		print TTLFILE "\nwait 'OMTB-OMTB application Finished'";
	}
	print TTLFILE "\nclosesbox";
	print TTLFILE "\nsetdir '$RESULTLOCATION\\$DIRNAME\\Testresults'";
	print TTLFILE "\nsendln";
	print TTLFILE "\ngettime endtime \"%H:%M:%S,\"";
	print TTLFILE "\nstrconcat TestCaseID 'P,'";
	print TTLFILE "\nstrconcat TestCaseID startime";
	print TTLFILE "\nstrconcat TestCaseID endtime";
	print TTLFILE "\nstrconcat TestCaseID date";

	print TTLFILE "\n       call updatefile";
	print TTLFILE "\nexit";

	print TTLFILE "\n:updatefile";
	print TTLFILE "\n	fileopen fhandle 'testresults.csv' 1";
	print TTLFILE "\n	filewriteln fhandle TestcaseID";
	print TTLFILE "\n	fileclose fhandle";
	print TTLFILE "\n	call restorepreviousdirectory";
	print TTLFILE "\npause 2";
	print TTLFILE "\n	return";

	print TTLFILE "\n:error";
	print TTLFILE "\n	fileopen fhandle 'testresults.csv' 1";
	print TTLFILE "\n	temp = TestCaseID";
	print TTLFILE "\n	gettime endtime \"%H:%M:%S,\"";
	print TTLFILE "\n	strconcat temp 'F,'";
	print TTLFILE "\n	strconcat temp startime";
	print TTLFILE "\n	strconcat temp endtime";
	print TTLFILE "\n	strconcat temp date";
	print TTLFILE "\n	filewriteln fhandle temp";
	print TTLFILE "\n	fileclose fhandle";
	print TTLFILE "\n	sendln 'Testcase failed'";
	print TTLFILE "\n	call restorepreviousdirectory";
	print TTLFILE "\n	exit";
	print TTLFILE "\n:restorepreviousdirectory";
	print TTLFILE "\nsetdir previousdirectory";
	print TTLFILE "\npause 2";
	print TTLFILE "\nreturn";
	close(TTLFILE);
}


sub reset_board()
{
	my $path = "$RELAYSWITCHPATH";
	print "\n Path = $path";
	chdir($path);	

	system("reset.bat");

	my $command = "taskkill /F /IM ttermpro.exe";
	system($command);
	$command = "taskkill /F /IM ttpmacro.exe";
	system($command);
	
}

sub launch_boot_ttl()
{
	my $command = "taskkill /F /IM ttermpro.exe";
	system($command);
	$command = "taskkill /F /IM ttpmacro.exe";
	system($command);
	$command = "\"c:\\Program Files\\teraterm\\ttpmacro.exe\" /I $RESULTLOCATION\\$DIRNAME\\TTL\\ducati_boot_script.ttl";
	system($command);
}

sub parse_csv 
{
	my $text = shift;
	my @new  = ();
	push( @new, $+ ) while $text =~ m{
		"([^\"\\]*(?:\\.[^\"\\]*)*)",?
		|  ([^,]+),?
		| ,
	}gx;
	push( @new, undef ) if substr( $text, -1, 1 ) eq ',';
	return @new;
}

sub generate_html_and_overall_report($$)
{
	my $inputfile = shift;
	my $outputfile = shift;
	
	my $DEBUG = 0;
	my %hash = ();
	my $file;
	my $comp;
	my $key;
	my @componentlist = ( "H264E" , "H264D" , "JPEGD", "mpeg4venc", "MPEG4D", "cam", "VC1", "VP6", "VP7");


	open( INFILE, "$inputfile" )
		or die("Can not open input file: $!");

	my @lines = <INFILE>;
	close(INFILE);

	open( INFILE, "$inputfile" )
		or die("Can not open input file: $!");

	my $total_testcases = 0;
	my $total_pass = 0;
	my $total_fail = 0;
	my $pass = 0;
	my $fail = 0;

	while ( $file = <INFILE> ) 
	{
		my @field = parse_csv($file);
		chomp(@field);

		print "\n field[0] = $field[0]" if $DEBUG;
		print "\n field[1] = $field[1]" if $DEBUG;
		print "\n field[2] = $field[2]" if $DEBUG;
		print "\n field[3] = $field[3]" if $DEBUG;
		print "\n field[4] = $field[4]" if $DEBUG;

		if(exists $hash{$field[0]})
		{
			my $value = $hash{$field[0]};
			my @temp = parse_csv($value);
			chomp(@temp);
			print "\n field[0] = $temp[0]" if $DEBUG;
			print "\n field[1] = $temp[1]" if $DEBUG;
			print "\n field[2] = $temp[2]" if $DEBUG;

			$temp[0] = $temp[0]+1;

			if($field[1] eq "P")
			{
				$temp[1] = $temp[1] + 1;
			}
			else
			{
				$temp[2] = $temp[2] + 1;
			}
			$hash{$field[0]} = "$temp[0],$temp[1],$temp[2]";

			#print "\n Exists";
		}
		else
		{
			#$hash{$field[0]} = "hello,world,man";
			if($field[1] eq "P")
			{
				$pass = 1;
				$fail = 0;
			}
			else
			{
				$pass = 0;
				$fail = 1;
			}
			$hash{$field[0]} = "1,$pass,$fail";
		}

		$total_testcases++;
		if($field[1] eq "P")
		{
			$total_pass++;
		}
		else
		{
			$total_fail++;
		}
	}

	close(INFILE);
	print %hash if $DEBUG;

	open(HTMLFILE, ">$outputfile");
	print HTMLFILE "<head><title> Ducati Daily Build - Test summary </title></head>";
	print HTMLFILE "<h2> Overall Test Summary </h2>";	

	my $uniquepass = 0;
	my $uniquefail = 0;
	foreach $key (sort keys %hash)
	{
		print "\n$key: $hash{$key}" if $DEBUG;
		print "\n Size of hash: ", scalar keys(%hash) if $DEBUG;

		my @temp = parse_csv($hash{$key});
		chomp(@temp);
		print "\n field[0] = $temp[0]" if $DEBUG;
		print "\n field[1] = $temp[1]" if $DEBUG;
		print "\n field[2] = $temp[2]" if $DEBUG;

		if($temp[0] == $temp[1])
		{
			$uniquepass += 1;
		}
		else
		{
			$uniquefail += 1;
		}
	}
	my $uniquetotal = $uniquepass + $uniquefail;

	print HTMLFILE "<table border='1' width='15%'>";
	print HTMLFILE "<tr><td><b>Total unique tests run</b></td>";
	print HTMLFILE "<td align='center'>".$uniquetotal."</td></tr>";
	print HTMLFILE "<tr><td><b>Total Pass </b></td>";
	print HTMLFILE "<td align='center'>".$uniquepass."</td></tr>";
	print HTMLFILE "<tr><td><b>Total Fail </b></td>";
	print HTMLFILE "<td align='center'>".$uniquefail."</td></tr>";
	print HTMLFILE "</table>";


	print HTMLFILE "<table border='1' width='40%'>";
	print HTMLFILE "<h2> Component Result Breakup </h2>";
	print HTMLFILE "<th>Component Name </th><th>Total tests run </th><th>Total Pass </th><th>Total Fail </th>";
	foreach $comp (@componentlist)
	{
		$uniquepass = 0;
		$uniquefail = 0;
		foreach $key (sort keys %hash)
		{
			if($key =~ m/$comp/)
			{
				print "\n$key: $hash{$key}" if $DEBUG;
				print "\n Size of hash: ", scalar keys(%hash) if $DEBUG;

				my @temp = parse_csv($hash{$key});
				chomp(@temp);
				print "\n field[0] = $temp[0]" if $DEBUG;
				print "\n field[1] = $temp[1]" if $DEBUG;
				print "\n field[2] = $temp[2]" if $DEBUG;

				if($temp[0] == $temp[1])
				{
					$uniquepass += 1;
				}
				else
				{
					$uniquefail += 1;
				}
			}
		} 
		my $uniquetotal = $uniquepass + $uniquefail;
		print HTMLFILE "<tr><td width='15%'>$comp</td><td width='7%' align='center'>$uniquetotal</td><td width='7%' align='center'>$uniquepass</td><td width='7%' align='center'>$uniquefail</td></tr>";
	}
	print HTMLFILE "</table>";


	print HTMLFILE "<table border='1' width='60%'>";
	print HTMLFILE "<h2> Failed Testcase Report </h2>";
	print HTMLFILE "<th>Testcase ID</th><th>Start time</th><th>End time</th><th>Date</th><th>Log</th>";

	open(FAILEDTESTS, "<$inputfile");
	my @failedtests = <FAILEDTESTS>;
	close(FAILEDTESTS);

	my $line;
	foreach $line (@failedtests)
	{
		if($line =~ m/,F,/)
		{
			my @failure = parse_csv($line);
			chomp(@failure);
			my $logfile = get_log_file_with_start_time_on_date("$RESULTLOCATION\\$DIRNAME\\Logs", "$failure[2]", "$failure[4]");
			print "\n Log file = $logfile" if $DEBUG;
			print HTMLFILE "<tr><td width='15%'>$failure[0]</td><td width='7%' align='center'>$failure[2]</td><td width='7%' align='center'>$failure[3]</td><td width='7%' align='center'>$failure[4]</td><td width='10%' align='center'><a href='../Logs/$logfile'>Log</a></td></tr>";

		}
	}
	print HTMLFILE "</table>";


	#get_file_with_modifiedtime("..\\Perl\\test","02:48:00");
	##open(HTMLFILE, ">$outputfile");

	print HTMLFILE "<head><title> Ducati Daily Build - Test summary </title></head>";
	print HTMLFILE "<h2> Overall Summary </h2>";

# SET UP THE TABLE
	print HTMLFILE "<table border='1' width='15%'>";
	print HTMLFILE "<tr><td><b>Total tests run</b></td>";
	print HTMLFILE "<td align='center'>".$total_testcases."</td></tr>";
	print HTMLFILE "<tr><td><b>Total Pass </b></td>";
	print HTMLFILE "<td align='center'>".$total_pass."</td></tr>";
	print HTMLFILE "<tr><td><b>Total Fail </b></td>";
	print HTMLFILE "<td align='center'>".$total_fail."</td></tr>";
	print HTMLFILE "</table>";


	print HTMLFILE "<h2> Detailed Summary </h2>";
	print HTMLFILE "<table border='1'>";
	print HTMLFILE "<th>Testcase </th><th>Total Runs</th><th>Total Pass</th><th>Total Fail</th>";

	foreach $key (sort keys %hash) {
		print "\n$key: $hash{$key}" if $DEBUG;
		print HTMLFILE "<tr><td>".$key."</td>";
		my @temp = parse_csv($hash{$key});
		chomp(@temp);
		print HTMLFILE "<td align='center'>".$temp[0]."</td>";
		print HTMLFILE "<td align='center'>".$temp[1]."</td>";
		if($temp[2] > 0)
		{
			print HTMLFILE "<td bgcolor='red' align='center'>".$temp[2]."</td></tr>";
		}
		else
		{
			print HTMLFILE "<td bgcolor='white' align='center'>".$temp[2]."</td></tr>";
		}
	}
	print HTMLFILE "</table>";

	close(HTMLFILE);


}

sub get_log_file_with_start_time_on_date($$$)
{
	my $dir = shift;
	my $starttime = shift;
	my $date = shift;

	my $file;
	my @files;

	my $DEBUG =0;
	my $comparedate;
	my $comparetime;
	my $previousfile;

	print "\n Dir = $dir" if $DEBUG;
	print "\n Starttime = $starttime" if $DEBUG;
	print "\n D1te = $date" if $DEBUG;

	@files = get_list_of_files("$dir");
	my $index = 0;
	foreach $file (@files)
	{
		$file =~ s/\\/\//g;
		my ($ignore, $file) = $file =~ m/(.*\/)(.*)$/;
		print "\n $file" if $DEBUG;
		my ($fileprefix, $filedate, $filetime, $extn) = $file =~ m/(.*\_)(.*\-)(.*\.)(.*)$/;
		chop($filetime);
		chop($filedate);
		print "\n $ignore" if $DEBUG; 
		print "\n $fileprefix" if $DEBUG;
		print "\n $filedate" if $DEBUG;
		print "\n $filetime" if $DEBUG;
		print "\n $extn" if $DEBUG;

		my ($sthour, $stmin, $stsec) = $starttime =~ m/(.*\:)(.*\:)(.*)$/; 
		chop($sthour);
		chop($stmin);
		print "\n $sthour, $stmin, $stsec"if $DEBUG; 

		my ($dtyear, $dtmon, $dtday) = $date =~ m/(.*\-)(.*\-)(.*)$/; 
		chop($dtyear);
		chop($dtmon);
		print "\n $dtyear, $dtmon, $dtday" if $DEBUG;
		print "\n" if $DEBUG;

		$comparedate = "$dtyear$dtmon$dtday";
		$comparetime = "$sthour$stmin$stsec";
		$previousfile;

		print "\n Compare = $comparedate" if $DEBUG;
		print "\n Compare = $comparetime" if $DEBUG;

		if($comparedate == $filedate)
		{
			print "\n I am here - $file" if $DEBUG;
			if($filetime > $comparetime)
			{
				print "\n Index = $index" if $DEBUG;
				if($index == 0)
				{
					return $file;
				}
				else
				{
					return $previousfile;
				}
			}
			else
			{
				$previousfile = $file;
			}

		}
		else
		{
			$previousfile = $file;
		}

		$index++;
	}
}

sub prepare_file_list_report($$$)
{
	my $DEBUG = 0;
	my $omsdir = shift;
	my $inputfiledirectory = shift;
	my $componentname = shift;

	my @omsfiles = get_list_of_files($omsdir);
	my @inputfiles = get_list_of_files($inputfiledirectory);
	my $inputfile;

	my @omsfilelist = ();

	print "\n Processing the input oms files and input files for $componentname";
	print "\n Error tests will be excluded from run";

	open(REPORT, ">$CURRENTDIR\\filecheckreport-$componentname.csv");
	my $omsfile;
	foreach $omsfile (@omsfiles)
	{
		if($omsfile =~ m/oms$/)
		{
			print "\n $omsfile " if $DEBUG;
			$omsfile =~ s/\//\\/g;

			open(MYFILE, $omsfile );
			my @omsfilecontent = <MYFILE>;
			close(MYFILE);

			my ($omsfilepath, $omsfilename) = $omsfile =~ m/(.*\\)(.*)$/;
			print "\n OMS File = $omsfile" if $DEBUG;
			print "\n OMS File path = $omsfilepath" if $DEBUG;
			print "\n OMS File Name = $omsfilename" if $DEBUG;

			my $omsfileline;
			foreach $omsfileline (@omsfilecontent)
			{
				if($omsfileline =~ m/infile/)
				{
					print "\n Line = $omsfileline" if $DEBUG;
					my ($ignore, $inputfilename) = $omsfileline =~ m/(.*\/)(.*)$/;
					print "\n File name = $inputfilename" if $DEBUG;

					my $found = 0;
					foreach $inputfile (@inputfiles)
					{
						if($inputfile =~ m/$inputfilename/)
						{
							$found = 1;
						}

					}

					if($found == 1)
					{
						print "\n File found" if $DEBUG;
						print REPORT "$omsfilepath, $omsfilename, $inputfilename, YES \n";
					}
					else
					{
						print "\n File not found" if $DEBUG;
						print REPORT "$omsfilepath, $omsfilename, $inputfilename, NO \n";

						push @omsfilelist, $omsfilename;
					}

				}

				if($omsfileline =~ m/frame_size/)
				{
					print "\n Line = $omsfileline" if $DEBUG;
					my ($ignore, $framesizefilename) = $omsfileline =~ m/(.*\/)(.*)$/;
					print "\n File name = $framesizefilename" if $DEBUG;

					my $found = 0;
					foreach $inputfile (@inputfiles)
					{
						if($inputfile =~ m/$framesizefilename/)
						{
							$found = 1;
						}

					}

					if($found == 1)
					{
						print "\n File found" if $DEBUG;
						print REPORT "$omsfilepath, $omsfilename, $framesizefilename, YES \n";
					}
					else
					{
						print "\n File not found" if $DEBUG;
						print REPORT "$omsfilepath, $omsfilename, $framesizefilename, NO \n";

						push @omsfilelist, $omsfilename;
					}


				}
			}
		}
	}
	close(REPORT);

	open(IGNORE, ">$CURRENTDIR\\$componentname-autogen-ignore.txt");
	my $date = get_current_date();
	my $time = get_current_time();
	print IGNORE "\n\nAutogenerated list of files to ignore - Date: $date - Time: $time";
	my @uniquelist = unique(@omsfilelist);
	my $uniqueelement;
	foreach $uniqueelement (@uniquelist)
	{
		my ($name, $extension) = $uniqueelement =~ m/(.*\.)(.*)$/;
		chop($name);
		print "\n Name = $name" if $DEBUG;
		print IGNORE "\n$name";
		print "\n Extension = $extension" if $DEBUG;
	}
	print @uniquelist;
	close(IGNORE);

}


sub unique
{
        my @uniq;
        my %seen = ();
        @list = @_;
        foreach $item (@list)
        {
                push(@uniq, $item) unless $seen{$item}++;
        }

        return @uniq;
}

sub filediff($$)
{
	my $oldfile = shift;
	my $newfile = shift;
	my @difflines;

	open OLDFILE, $oldfile or die "$!";
	open NEWFILE, $newfile or die "$!";
	my %diff;

	$diff{$_}=1 while (<OLDFILE>);

	while(<NEWFILE>){
		push (@difflines, $_) unless $diff{$_};
	}

	close NEWFILE;
	close OLDFILE;

	return @difflines;
}

sub convertfile($)
{
	my $file = shift;
	my $line;

	open MYFILE, $file or die "$!";
	my @lines = <MYFILE>;
	close(MYFILE);

	open(MYFILE, ">$file-mod.txt");
	foreach $line (@lines)
	{
		my($needed, $ignore) = $line =~ m/(.*Rule:)(.*)$/;
		chop($needed);
		chop($needed);
		chop($needed);
		chop($needed);
		chop($needed);
		print MYFILE "\n$needed";
	}
	close(MYFILE);
}

sub filediff_report($$$$)
{
	my $file1 = shift;
	my $file2 = shift;
	my $report = shift;
	my $label = shift;
	my $DEBUG = 0;

	convertfile($file1);
	convertfile($file2);

	my @lines = filediff("$file1-mod.txt", "$file2-mod.txt");
	unlink("$file1-mod.txt");
	unlink("$file2-mod.txt");
	print @lines if $DEBUG;

	my $line;
	open(REPORT, ">$report");
	print REPORT "\n ---------------------------------------------------------------------- ";
	print REPORT "\n List of modified files in dailybuild - $label ";
	print REPORT "\n ---------------------------------------------------------------------- ";
	print REPORT "\n";
	foreach $line (@lines)
	{
		my($file, $ignore) = $line =~ m/(.*\@\@)(.*)$/;	
		chop($file); chop($file);
		print "\n $file" if $DEBUG;
		print REPORT "\n $file";
	}
	close(REPORT);
}

sub check_for_while_loop_hang()
{
	my $DEBUG = 0;
	my $latestlogfile = get_latest_file_in_dir("$RESULTLOCATION\\$DIRNAME\\Logs\\");
	print "\n The log file is $latestlogfile" if $DEBUG;

	open(LOGFILE, "$latestlogfile");
	my @logfile = <LOGFILE>;
	close(LOGFILE);

	@lastlineslogfile = @logfile[-10..-1];
	print "\n The last 10 lines of the file is below" if $DEBUG;
	print @lastlineslogfile if $DEBUG;

	my $index = 0;
	my $matchcount = 0;
	foreach $line (@lastlineslogfile)
	{
		print "\n Line from previous log - @LASTLINES[$index]" if $DEBUG;
		print "\n Line from current log - $line" if $DEBUG;
		if($line eq @LASTLINES[$index])
		{
			$matchcount++;
			print "\n The lines match" if $DEBUG;
		}
		else
		{
			print "\n The lines do not match" if $DEBUG;
		}
		$index++;
	}

	@LASTLINES = @lastlineslogfile;

	if($matchcount == 10)
	{
		$WHILELOOPMONITORCOUNT++;
	}
	else
	{
		$WHILELOOPMONITORCOUNT = 0;
	}


	if($WHILELOOPMONITORCOUNT == 3)
	{
		return 1;
	}
	else
	{
		return 0;
	}

}

sub generate_test_report_for_cq_update($$)
{
	my $DEBUG = 0;
	my $inputfile = shift;
	my $outfile = shift;
	my %hash = ();
	my $file;
	my $key;

	open( INFILE, "$inputfile" )
		or die("Can not open input file: $!");

	my @lines = <INFILE>;
	close(INFILE);

	open( INFILE, "$inputfile" )
		or die("Can not open input file: $!");

	my $pass = 0;
	my $fail = 0;

	while ( $file = <INFILE> ) 
	{
		my @field = parse_csv($file);
		chomp(@field);

		print "\n field[0] = $field[0]" if $DEBUG;
		print "\n field[1] = $field[1]" if $DEBUG;
		print "\n field[2] = $field[2]" if $DEBUG;
		print "\n field[3] = $field[3]" if $DEBUG;
		print "\n field[4] = $field[4]" if $DEBUG;

		if(exists $hash{$field[0]})
		{
			my $value = $hash{$field[0]};
			my @temp = parse_csv($value);
			chomp(@temp);
			print "\n field[0] = $temp[0]" if $DEBUG;
			print "\n field[1] = $temp[1]" if $DEBUG;
			print "\n field[2] = $temp[2]" if $DEBUG;

			$temp[0] = $temp[0]+1;

			if($field[1] eq "P")
			{
				$temp[1] = $temp[1] + 1;
			}
			else
			{
				$temp[2] = $temp[2] + 1;
			}
			$hash{$field[0]} = "$temp[0],$temp[1],$temp[2]";
		}
		else
		{
			if($field[1] eq "P")
			{
				$pass = 1;
				$fail = 0;
			}
			else
			{
				$pass = 0;
				$fail = 1;
			}
			$hash{$field[0]} = "1,$pass,$fail";
		}

	}

	close(INFILE);
	print %hash if $DEBUG;


	open(OUTFILE, ">>$outfile");
	foreach $key (sort keys %hash)
	{
		print "\n$key: $hash{$key}" if $DEBUG;
		print "\n Size of hash: ", scalar keys(%hash) if $DEBUG;

		my @temp = parse_csv($hash{$key});
		chomp(@temp);
		print "\n field[0] = $temp[0]" if $DEBUG;
		print "\n field[1] = $temp[1]" if $DEBUG;
		print "\n field[2] = $temp[2]" if $DEBUG;

		if($temp[0] == $temp[1])
		{
			print OUTFILE "\n$key;P";
		}
		else
		{
			print OUTFILE "\n$key;F";
		}
	}	
	close(OUTFILE);
}

sub update_cq_list_with_ignores_and_autogenignore($)
{
	my $outfile = shift;
	my @componentlist = ( "h264decoder" , "h264encoder" , "jpegdecoder", "mpeg4decoder", "mpeg4encoder", "vc1decoder", "vp6decoder", "vp7decoder");

	my $comp;
	my $line;

	open(OUTFILE, ">>$outfile");
	foreach $comp (@componentlist)
	{
		open(CQFILE, "<$CURRENTDIR\\$comp-ignore.txt");
		my @lines = <CQFILE>;
		close(CQFILE);

		print "\n Contents of $comp-ignore.txt is \n";
		print @lines;

		foreach $line (@lines)
		{
			chomp($line);
			if($line =~ m/;/ or $line =~ /^\s*$/)
			{
				print "\n Ignore - $line";
			}
			else
			{
				print OUTFILE "\n$line;U";
			}
		}

		open(CQFILE, "<$CURRENTDIR\\$comp-autogen-ignore.txt");
		my @lines = <CQFILE>;
		close(CQFILE);

		print "\n Contents of $comp-autogen-ignore.txt is \n";
		print @lines;

		foreach $line (@lines)
		{
			chomp($line);
			if($line =~ m/Autogenerated/ or $line =~ /^\s*$/)
			{
				print "\n Ignore - $line";
			}
			else
			{
				print OUTFILE "\n$line;F";
			}
		}
	}
	close(OUTFILE);
}
sub update_cq_with_results()
{
	my $DEBUG = 1;

	print "\n Inside the update CQ with results" if $DEBUG;

	my $prevdirname = get_yesterday_date();
	$prevdirname = $prevdirname . "-Ducati-Daily-Build-Report";
	print "\n Yesterday's directory name is $prevdirname" if $DEBUG;

	open(MYFILE, ">$RESULTLOCATION\\$prevdirname\\TestResults\\resultdump.txt");
	close(MYFILE);

	generate_test_report_for_cq_update("$RESULTLOCATION\\$prevdirname\\TestResults\\testresults.csv", "$RESULTLOCATION\\$prevdirname\\TestResults\\resultdump.txt");

	update_cq_list_with_ignores_and_autogenignore("$RESULTLOCATION\\$prevdirname\\TestResults\\resultdump.txt");

	open(MYFILE, "<$RESULTLOCATION\\$prevdirname\\TestResults\\resultdump.txt");
	@lines = <MYFILE>;
	print @lines;
	close(MYFILE);

	my $hostname = get_hostname();
	chomp($hostname);
	$inputview = $hostname . "_" . $DAILYBUILDVIEWNAME;
	
	chdir("M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\");
	my $command = "cleartool mkbranch -nc $INTGBRANCH M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	system($command);
	my $command = "cleartool ci -nc M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	system($command);
	my $command = "cleartool co -nc M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	system($command);

	my $shortpath = Win32::GetShortPathName($CURRENTDIR);
	my $command = "$shortpath\\TCRUpdater.exe -r $RESULTLOCATION\\$prevdirname\\TestResults\\resultdump.txt -w M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	print "\n Command = $command";
	system($command);

	my $command = "cleartool ci -nc M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	system($command);

	my $yesterdaydate = get_yesterday_date();
	my $command = "cleartool mklabel -replace $LABELFORMAT-$yesterdaydate M:\\$inputview\\WTSD_DucatiMMSW\\docs\\component_test\\test_result\\wtsd_ducatimmsw_test_results.xls";
	system($command);


}




#main()
$CURRENTDIR = cwd;
read_config_file();
setup_directory();

if($ENABLEBUILD eq "YES")
{
	$TRIALNUMBER = 0;

	startagain:
	$TRIALNUMBER++;
	$dailybuildview_configspec = "element * CHECKEDOUT \n element /WTSD_DucatiMMSW/... .../$INTGBRANCH/LATEST \n element /WTSD_DucatiMMSW/... $DUCATILABEL";
	delete_and_create_view($DAILYBUILDVIEWNAME, $dailybuildview_configspec);

	$result = find_checkouts($DAILYBUILDVIEWNAME);
	if($result == 1)
	{
		print "\n FATAL ERROR: There are checkouts on the branch $INTGBRANCH";
		print "\n The tool will check after 10 minutes\n";
		sleep 600;
		goto startagain;
	}

	create_snapshot($DAILYBUILDVIEWNAME, "snapshot-on-integrationbranch");
	my $cslabel = create_and_apply_label();

	$dailybuildlabeledview_configspec = "element /WTSD_DucatiMMSW/... $cslabel \nelement /WTSD_DucatiMMSW/... $DUCATILABEL";
	delete_and_create_view($DAILYBUILDLABELEDVIEWNAME, $dailybuildlabeledview_configspec);
	create_snapshot($DAILYBUILDLABELEDVIEWNAME, "snapshot-on-dailybuildlabel");

	create_build_settings_and_build_ducati($DAILYBUILDLABELEDVIEWNAME);

	if(-e "out\\app_m3\\release\\base_image_app_m3.xem3")
	{
		my $command = "copy out\\app_m3\\release\\base_image_app_m3.xem3 $RESULTLOCATION\\$DIRNAME\\Build\\.";
		system($command);
		$command = "copy package\\cfg\\out\\app_m3\\release\\base_image_app_m3.xem3.map $RESULTLOCATION\\$DIRNAME\\Build\\.";
		system($command);
		$command = "cleartool catcs > $RESULTLOCATION\\$DIRNAME\\Build\\configspec.txt";
		system($command);

		my $currentdate = get_current_date();
		my $olddirname = get_yesterday_date();
		$olddirname = $olddirname . "-Ducati-Daily-Build-Report";
		my $old_file = "$RESULTLOCATION\\$olddirname\\BuildLogs\\snapshot-on-dailybuildlabel.txt";
		my $new_file = "$RESULTLOCATION\\$DIRNAME\\BuildLogs\\snapshot-on-dailybuildlabel.txt";
		filediff_report("$old_file", "$new_file", "$RESULTLOCATION\\$DIRNAME\\Build\\changedfiles.txt", "$LABELFORMAT-$currentdate");
	}
	else
	{
		my $output = `xdc -PD .`;
		open(MYFILE, ">$RESULTLOCATION\\$DIRNAME\\BuildLogs\\compilation-error-$TRIALNUMBER.txt");
		print MYFILE $output;
		close(MYFILE);
		goto startagain;
	}

	copy_build_to_filesystem();

}
else
{
	print "\n Enable build option disabled \n";
	sleep 2;
}

if($UPDATECQRESULTS eq "YES")
{
	update_cq_with_results();
}

if($ENABLETEST eq "YES")
{
	$omtbview_configspec = "element /omtb/... $OMTBLABEL \n element /omtb/... .../main/LATEST";
	delete_and_create_view($OMTBBUILDVIEWNAME, $omtbview_configspec);

	setup_tests_generate_ttl();
	setup_ttl();

	print "\n";
	restart_testcase:
	#Global variable for while loop detection
	$WHILELOOPMONITORCOUNT = 0;
	$thr1 = threads->create(\&interact_with_board);
	sleep 50;
	my $oldfilesize = 0;
	while(1)
	{
		my $filesize = get_filesize_of_latest_file_in_directory("$RESULTLOCATION\\$DIRNAME\\Logs\\");
		print "Size: $filesize\n" if $DEBUG;
		if($filesize == $oldfilesize)
		{
			print "\n There is no activity on the board for more than $TESTMONITORINTERVAL seconds. Restarting the testcase";
			print "\n";
			if($TESTMONITORMODE eq "MANUAL")
			{
				print "\n Do you want to reboot now? (y/n)";
				my $answer = <>;
				chomp($answer);
				if($answer eq "y" or $answer eq "Y")
				{
					$thr1->kill('KILL')->detach();
					goto restart_testcase;
				}
			}
			else
			{
				$thr1->kill('KILL')->detach();
				goto restart_testcase;
			}
		}
		else
		{
			my $time = get_current_time();
			my $date = get_current_date();
			my $whileloopstatus = check_for_while_loop_hang();

			#Check for while loop hang
			if($whileloopstatus)
			{
				print "\n The board appears to be stuck in while loop - proceeding to restart";
				$thr1->kill('KILL')->detach();
				goto restart_testcase;
			}


			print "\n Time: $time Date: $date ";
			print "\n Board status: OK";
			print "\n Next monitoring will be done in $TESTMONITORINTERVAL seconds\n";
		}
		$oldfilesize = $filesize;
		if(-e "$RESULTLOCATION\\$DIRNAME\\TestResults\\testresults.csv")
		{
			generate_html_and_overall_report("$RESULTLOCATION\\$DIRNAME\\TestResults\\testresults.csv","$RESULTLOCATION\\$DIRNAME\\TestResults\\report.html");
		}
		sleep $TESTMONITORINTERVAL;
		read_config_file();
	}

	my @ReturnData = $thr1->join();
}
else
{
	print "\n Enable test option disabled \n";
	sleep 2;
}
exit;


sub interact_with_board()
{
        # Thread 'cancellation' signal handler
        $SIG{'KILL'} = sub { threads->exit(); };
	
	reset_board();
	launch_boot_ttl();	

	while(1)
	{
		sleep 1;
	}
}


parse_command_line();
@filelist = get_list_of_files($DIR_PATH);
foreach $file (@filelist)
{
   print "\n $file";
}



sub replace_testcase($$)
{
	my $compname = shift;
	my $path = shift;
	my $testcase; 

	open(MYFILE, "$path");
	@lines = <MYFILE>;
	close(MYFILE);

	if($compname eq "h264dec")
	{
		$testcase = "TC_H264DEC_HDR_OMX.oms";
	}
	if($compname eq "vc1decoder")
	{
		$testcase = "TC_VC1DEC_HDR1_OMX.oms";
	}


	open(MYFILE, ">$path");
	foreach $line (@lines)
	{
		#print $line;
		if($line =~ m/omx -s Decoder/)
		{
			print "\nYes" if $DEBUG;
			$line =~ s/; sendln 'omx -s Decoder\.oms/sendln 'omx -s $testcase/;
			print "\n$line" if $DEBUG;
		}
		print MYFILE $line;

	}
	close(MYFILE);
}
