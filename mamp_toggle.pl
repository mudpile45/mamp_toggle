#!/usr/bin/perl
use strict;
use Getopt::Std;
use Socket;

if (scalar(@ARGV) < 1) {
    usage();
    die "Must provide at least one domain!";
}

my %opts;
getopts('ed', \%opts);

#TODO: autoset HOSTS_LOC based on architecture (e.g. windows)
use constant HOSTS_LOC   => '/etc/hosts'; # This needs to be changed on windows
use constant REDIRECT_IP => '127.0.0.1';

my $domain = shift;
my $direction = undef;
$direction = 1 if $opts{e};
$direction = -1 if $opts{d};

# print "!!!! >>>> $direction\n";
hosts($domain, $direction);
MAMP_Apache($domain, $direction);


sub MAMP_Apache {
    use constant HTTPD_CONF_DIR => '/Applications/MAMP/conf/apache';
    my ($domain, $direction) = @_;

    open HTTPD, HTTPD_CONF_DIR . "/httpd.conf";
    my @httpd = <HTTPD>;
    close HTTPD;
    my @httpd_out;
    my $disabled = undef;
    my $enabled  = undef;

    # Disable previously enabled domain
    foreach (@httpd) {
        my $httpconfdir = HTTPD_CONF_DIR;
        if (! m!Include $httpconfdir/$domain.conf!) {
            push (@httpd_out, $_); 
        }
        else {
            print "Removing Apache conf file Include for $httpconfdir/$domain.conf\n";
            # print;
            $disabled = 1;
        }
    }
    if (! $direction || $direction == -1) {
        if (-e HTTPD_CONF_DIR . "/$domain.conf") {
            print "Removing file  " . HTTPD_CONF_DIR . "/$domain.conf" . "\n";
            unlink (HTTPD_CONF_DIR . "/$domain.conf");
        }

        if ($disabled) {
            open HTTPD, ">" . HTTPD_CONF_DIR . "/httpd.conf";
            foreach (@httpd_out) {print HTTPD};
            close HTTPD;
        }
    }
    if ( (! $disabled || $direction == 1 ) && $direction != -1) {
        # Enable a new domain
        push(@httpd_out, "Include " . HTTPD_CONF_DIR . "/$domain.conf\n");
        open HTTPD, ">" . HTTPD_CONF_DIR . "/httpd.conf";
        foreach (@httpd_out) {print HTTPD};
        print "Adding new Apache conf file and include for " . HTTPD_CONF_DIR . "/$domain.conf\n";
        close HTTPD;


        open DOMAIN_CONF, ">" . HTTPD_CONF_DIR . "/$domain.conf";
        print DOMAIN_CONF "<VirtualHost 127.0.0.1>
        ServerName $domain
        ServerAlias www.$domain
        VirtualDocumentRoot /Applications/MAMP/htdocs/$domain
        </VirtualHost>";
        return "enabled";
    }
}

sub usage
{
    my $exe_name = $0;
    $exe_name =~ s!.*/!!;

    print "Usage:\n $exe_name domain\n";
}

sub hosts {
    my ($domain, $direction) = @_;

    local *hosts_remove = sub {
        my $hosts_data= shift(@_) ;
        my $line_number = 0;
        my $domain_set = undef;
        my @output_hosts;
        foreach my $host (@$hosts_data) {
            $line_number++;
            if ($host=~m/^#/ || $host !~ m/[0-9]/) { 
                push (@output_hosts, $host);
                next; }
            if ($host =~ m/$domain/) {
                print "$domain entry found in hosts file at line $line_number... Removing" . "\n"; 
                $domain_set = 1;
            }
            else {
                push (@output_hosts, $host);

            }
            @$hosts_data = @output_hosts;
        }
        return $domain_set;
    };

    local *hosts_add = sub {
        my $hosts_data = shift(@_);
        my @output_hosts;
        print "Adding $domain -> " . REDIRECT_IP . " redirect to " . HOSTS_LOC . "\n";
        push(@output_hosts, REDIRECT_IP . "\t$domain\n");
        push(@output_hosts, REDIRECT_IP . "\twww.$domain\n");

        # Insert a link to the orig IP
        my $ip;
        eval { $ip = inet_ntoa(inet_aton($domain)) };
        if ($ip) {
            push(@output_hosts, inet_ntoa(inet_aton($domain)) . "\torig.$domain\n"); 
        }

        @$hosts_data = (@$hosts_data, @output_hosts);
        return 1;
    };


    open HOSTS, HOSTS_LOC;
    my @hosts_data =  <HOSTS>;
    close HOSTS;


    if (! $direction) {
        if (! hosts_remove(\@hosts_data)) {
            hosts_add(\@hosts_data);
        }
    }
    elsif ($direction == 1) {   #force enable of redirect
        hosts_add(\@hosts_data);
    }
    elsif ($direction == -1) {  #force removal of redirect
        hosts_remove(\@hosts_data);
    }

    open TEMP, ">/tmp/tmp_host";
    foreach (@hosts_data) { print TEMP};
    # foreach (@hosts_data) { print };
    close TEMP;

    `sudo cp /tmp/tmp_host /etc/hosts`;
    unlink('/tmp/tmp_host');
}
