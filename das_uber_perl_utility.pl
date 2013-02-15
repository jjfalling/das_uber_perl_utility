#!/usr/bin/env perl
#This is used to interface with other programs that are not meant to be interactivly run.
# - JFalling 2012

use strict;
use warnings;
use Term::ANSIColor;
use Term::Cap;
use Data::Dumper;
########################################################################################
#NOTES:
#To define programs and prompters, create modules in ./das_uber_perl_utility_modules
# (see an exising module as an example or read me if I bothered to do one) Names must match
# the the name of the function inside the module you create (expecpt the .pl ext). CASE MATTERS!
#
########################################################################################
#User defined items

#DO edit these
my $PROGNAME = "Das Über Perl Utility";
our $default_comm = "private";
our $modules_dir = "/usr/local/adm/das_uber_perl_utility_modules";

#  *** STOP EDITING! SERIOUSLY, YOU MIGHT BREAK SOMETHING. LIKE YOUR BRAIN. GÅ BORT! ***

########################################################################################
#declare some things
my $null_var; #Anything we don't care about but need a variable for some sort of task, use this
my $valid_in = 0;
our $terminal = Term::Cap->Tgetent( { OSPEED => 9600 } );
our $clear_string = $terminal->Tputs('cl');
my @prog_array;
my $prog_to_run;
my $req_program;
my $prog_name;
my %avail_programs = ();
my $value;
my $key;

#open the modules folder
opendir (DIR, $modules_dir) or die $!;

while (my $file = readdir(DIR)) {

        # Use a regular expression to ignore files beginning with a period
        next if ($file =~ m/^\./);
        $value = $file;
        $key = $file;
        $key =~ s/.pl//;
        $avail_programs{$key} = $value;


}

closedir(DIR);

while ($valid_in == 0) {

        #clear the terminal window
        print $clear_string;

        #give a welcome message
        print color 'bold';
        print "\n\nWelcome to $PROGNAME!\n\n";
        print color 'reset';

        print "Use this program to interact with programs that are not meant to be run interactivly or are not so friendly.\n";
        print colored ['red'], "Note:", color("reset");
        print " programs are sorted by name, if you add or remove a program, the number will change!.\n\n";
        print "Available programs:\n\n";

        my $prog_count = -1;


		foreach my $key ( sort keys %avail_programs ){
                $prog_count++;
                print "$prog_count: $key\n";
                $prog_array[$prog_count] = "$key";


        }

        #Ask for and get input from user
        print "\nPlease enter the program number you want to run: ";
        $req_program = <>;
        chomp ($req_program);

        #see if the input was a letter
        if ($req_program !~ /^[+-]?\d+$/ ) {

                #Since invalid input was given, insult the user
                print color 'bold red';
                print "\n\nWhat the hell? \"$req_program\" is not a number! Don't make me replace you with a small perl script…\n";
                print color 'reset';
                print "\nHit return to try again…. ";
                $null_var = <>;

        }

        #see if the number is within a specified range
        elsif ( $req_program < 0 || $req_program > $prog_count) {

                #Since invalid input was given, insult the user
                print color 'bold red';
                print "\n\nYou did not enter a valid number (0 - $prog_count)! No soup for you!\n";
                print color 'reset';
                print "\nHit return to try again…. ";
                $null_var = <>;

        }
        else {
        $valid_in = 1;
        }
}

#since the input passed basic validation, lets find the prompter
our $name_of_prog = $prog_array[$req_program];
$prog_to_run = "$avail_programs{$name_of_prog}";
my $function_to_run = "$name_of_prog";
#hack due to strict not allowing what I want to do...
my $subref = \&$function_to_run;

require "$modules_dir/$name_of_prog.pl";

#try to run the function
&$subref($default_comm, $name_of_prog, $clear_string);


########################################################################################
#Functions that users shouldnt edit


#Well shucks, we made it all the way down here with no errors. Guess we should exit without an error ;)
exit 0;
