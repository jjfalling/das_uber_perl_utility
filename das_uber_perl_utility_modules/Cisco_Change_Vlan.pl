#interactive prompter for snmp_rename_port
#Pulls machine data from an api, in our case a modified version of rackmonkey

my $prog_name = "/usr/local/adm/cisco_change_vlan.pl";

sub Cisco_Change_Vlan {

	my ($default_comm, $name_of_prog, $clear_string) = @_;

	use JSON qw( decode_json );     # From CPAN
	use Data::Dumper;               # Perl core module
	use strict; 
	use warnings; 
	use LWP::UserAgent;
	use Term::ANSIColor;
	use Term::Cap;

	#disable host verify with ssl
	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

	#garbage var
	my $null_var;
	my $remote_device;
	my $interface;
	our $full_label;

	#change the following to match your api
	my $ua = LWP::UserAgent->new;
	$ua->agent("MyApp/0.1 ");
	$ua->credentials(
		 'assetdb.company.org:443',
		 'Secret Area',
		 'api' => 'omgletmein!'
		 );
	
	#clear the terminal window
	print $clear_string;

	#give a welcome message
	print color 'bold';
	print "\n\nWelcome to $name_of_prog  \n";
	print color 'reset';
	
	print "\nWhat is the hostname of the server or device of whom you wish to change its access vlan?: ";
	my $hostname = <>;
	chomp ($hostname);
	
	#if does not contain the "bil1" assume the hostname is invalid
	if ($hostname !~ /bil1-/) {
		print color 'bold red';
		print "ERROR: Invalid hostname, must contain \"bil1\"\n";
		print color 'reset';
		exit(2);
	}
	
	print "\nWhat access vlan ID do you want $hostname to be on? ";
	my $vlan = <>;
	chomp ($vlan);
	
	print "\nPlease wait, doing API query... \n";
	
	# get JSON info from rackmonkey API on this device
	my $device_url = "https://assetdb.company.org/?view=device&view_type=default_single_api&device_search=$hostname";	
	my $req = HTTP::Request->new(GET => $device_url);
	my $res = $ua->request($req);
	
	# Check the outcome of the response
	if ($res->is_success) {
		my $device = decode_json($res->content);
		if ($device->{'result'} eq 'error') {
			print color 'bold red';
			print "ERROR: $device->{'message'}\n";
			print color 'reset';
			exit(2);
		}
	
		# role 21 is network
		my $consRef = getPortsByRole($device, 21);
		our @cons = @{$consRef};
		our $num_of_cons = scalar @cons;
		
		if ($num_of_cons == 0) {
			print color 'bold red';
			print "No active network connections in RackMonkey for $device->{'name'}... exiting\n";
			print color 'reset';
	
			exit(2);
		}
		
		elsif ($num_of_cons == 1) {
			print "Found one network connection for $device->{'name'}: $cons[0]->{'local_port'} \(connected to $cons[0]->{'remote'} $cons[0]->{'remote_port'}\)  \n";
			$interface = $cons[0]->{'remote_port'};
			$remote_device = $cons[0]->{'remote'};
		} 
		
		elsif ($num_of_cons > 1) {
			my $valid_in = 0;
			while ($valid_in == 0) {
				print "\nMore then one network connection for $device->{'name'} found: \n";
				our $array_element = 0;
				while ($array_element < $num_of_cons) {
					print "$array_element: $cons[$array_element]->{'local_port'} \(connected to $cons[$array_element]->{'remote'} $cons[$array_element]->{'remote_port'}\) \n";
					$array_element++;
				}
				
				print "Enter the numerical selection of the port you wish to change: ";
				my $req_port = <>;
				chomp ($req_port);
				
				#see if the input was a letter
				if ($req_port !~ /^[+-]?\d+$/ ) {
				
						#Since invalid input was given, insult the user
						print color 'bold red';
						print "\n\n \"$req_port\" is not a number! \n";
						print color 'reset';
						print "\nHit return to try again…. ";
						$null_var = <>;
				
				}
				
				#see if the number is within a specified range
				elsif ( $req_port < 0 || $req_port > ($num_of_cons - 1)) {
				
						#Since invalid input was given, insult the user
						print color 'bold red';
						print "\n\nYou did not enter a valid number (0 - ",($num_of_cons - 1),")!\n";
						print color 'reset';
						print "\nHit return to try again…. ";
						$null_var = <>;
				
				}
				else {
				$valid_in = 1;
				$interface = $cons[$req_port]->{'remote_port'};
				$remote_device = $cons[$req_port]->{'remote'};
				
				}
			}
		}
		convertSwitchPort($interface);
	
	} else {
		print color 'bold red';
		print "ERROR: API Request error: \n";
		print $res->status_line, "\n";
		print color 'reset';
		exit(1);
	}
	
	print "\nSet port $full_label on $remote_device to vlan ID $vlan?\n";
	print "Press enter to continue or CTRL+C to exit...";
	$null_var = <>;
	
	#run the program....
	system ("$prog_name -H $remote_device  -v $vlan -p $full_label -w $default_comm -n $hostname -d");

}


#we are updating rm to have gi/1/0/4, etc. ports will have gi:* or fe:*. we will take that and convert it to a full name ex: GigabitEthernet, etc...
#here is a sub that will do this for us
sub convertSwitchPort {
	my $interface2 = shift;
	

	#split the sting at the first occurrence of a digit
	(my $prefix, my $port_two, my $port_three) = split(/(\d+)/, $interface2, 2);
	#combine the split char and the rest of the string
	my $postfix = "$port_two$port_three";

	#check if interface is gige     
	if ($prefix =~ /gi/i) {
		$prefix = "GigabitEthernet";
	}

	#check if interface is fast ethernet
	elsif ($prefix =~ /fa/i) {
		$prefix = "FastEthernet";
	}

	else {
		print color 'bold red';
		print "ERROR: Unknown or missing port prefix found in rack monkey. I found: $prefix, I expect the interface to start with Gi or Fa. Exiting.....";
		print color 'reset';
		exit(2);
	}

	#re-define port with proper name
	$full_label = "$prefix$postfix";
	

	return $full_label;
}
        
sub getPortsByRole { 
	my ($device, $role) = @_;

	my @cons;
		foreach my $port (@{$device->{'outbound_conn'}}) {
		push @cons, $port if ($port->{'role'} == $role);
	}

	return \@cons;
}

#the next line is required for perl to import the file
1;
