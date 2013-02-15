#interactive prompter for snmp_rename_port
use strict;
my $null_var;

my $prog_name = "/usr/local/adm/snmp_rename_port.pl";

sub SNMP_Rename_Port {

        my ($default_comm, $name_of_prog, $clear_string) = @_;
	
	#clear the terminal window
	print $clear_string;

	#give a welcome message
	print color 'bold';
	print "\n\nWelcome to $name_of_prog  \n";
	print color 'reset';

	print "\nWhat is the hostname or ip of device you want to make your change on? ";
	my $req_hname = <>;
	chomp ($req_hname);

	print "\nWhat is the interface you want to name (exact same as on the device, case sensitive)? ";
	my $req_int = <>;
	chomp ($req_int);

	print "\nWhat do you want to name that interface? ";
	my $req_intname = <>;
	chomp ($req_intname);
	
	print "\n\nSet name \(alias\) of $req_int to $req_intname on $req_hname? \nPress enter to continue or CTRL+C to exit ";
	$null_var = <>;
	
	#run the correct program:
	system ("$prog_name -H $req_hname -p $req_int -n \"$req_intname\" -w $default_comm -d");

}
#the next line is required for perl to import the file
1;
