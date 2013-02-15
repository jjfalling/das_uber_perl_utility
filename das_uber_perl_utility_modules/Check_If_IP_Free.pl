#interactive prompter for snmp_rename_port
my $prog_name = "/usr/local/adm/cisco_check_ip.pl";
my $req_ip;
my $req_hname;
my $continue = 0;
my $null_var;

use strict;

sub Check_If_IP_Free {

	my ($default_comm, $name_of_prog, $clear_string) = @_;

	while ($continue eq 0){

		#clear the terminal window
		print $clear_string;

		#give a welcome message
		print color 'bold';
		print "\n\nWelcome to $name_of_prog  \n";
		print color 'reset';

		print "\nWhat is the hostname or ip of device you want to run this check on? ";
		my $req_hname = <>;
		chomp ($req_hname);

		print "\nWhat is the IP address you want to check if it is in use or not? ";
		my $req_ip = <>;
		chomp ($req_ip);

		print "\n\nCheck to see if $req_ip is free on $req_hname? \nPress enter to continue or CTRL+C to exit ";
		$null_var = <>;
	
		#run the correct program:
		system ("$prog_name -H $req_ip -c $req_hname -C $default_comm -d");
		
		#see if the user want to run this again
                print "\n\nDo you want to check another ip? \Press enter to run again or CTRL+C to exit";
                $null_var = <>;

	}
}
#the next line is required for perl to import the file
1;
