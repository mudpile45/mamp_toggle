#!/usr/bin/perl
use strict;
use Getopt::Long;

#TODO: autoset HOSTS_LOC based on architecture
use constant HOSTS_LOC   => '/etc/hosts'; # This needs to be changed on windows
use constant REDIRECT_IP => '127.0.0.1';

open HOSTS, HOSTS_LOC;
my @hosts_data =  <HOSTS>;
close HOSTS;

# print join("", @hosts_data);

my $domain = shift(@ARGV);
# print "$domain\n";

my @output_hosts;
my $line_number = 0;
my $domain_set = undef;
foreach my $host (@hosts_data) {
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
}

if (! $domain_set) {
    print "$domain not found in hosts file... Redirecting to " . REDIRECT_IP . "\n";
    push(@output_hosts, REDIRECT_IP . "\t$domain\n");
    push(@output_hosts, REDIRECT_IP . "\twww.$domain\n");
}

open TEMP, ">/tmp/tmp_host";
foreach (@output_hosts) { print TEMP};
close TEMP;

`sudo cp /tmp/tmp_host /etc/hosts`;
unlink('/tmp/tmp_host');

print MAMP_Apache($domain);


sub MAMP_Apache {
    use constant HTTPD_CONF_DIR => '/Applications/MAMP/conf/apache/';
    my $domain = shift;

    open HTTPD, HTTPD_CONF_DIR . "/httpd.conf";
    my @httpd = <HTTPD>;
    close HTTPD;
    my @httpd_out;
    my $disabled = undef;
    my $enabled  = undef;

    # Disable previously enabled domain
    foreach (@httpd) {
        if (! m!Include /Applications/MAMP/conf/apache/$domain.conf!) {
            push (@httpd_out, $_); 
        }
        else {
            print "Removing line: \n";
            print;
        }
    }
    if (-e HTTPD_CONF_DIR . "/$domain.conf") {
        print "Removing file  " . HTTPD_CONF_DIR . "/$domain.conf" . "\n";
        unlink (HTTPD_CONF_DIR . "/$domain.conf");
        $disabled = 1;
    }

    if ($disabled) {
        open HTTPD, ">" . HTTPD_CONF_DIR . "/httpd.conf";
        foreach (@httpd_out) {print HTTPD};
        close HTTPD;
        return "disabled";
    }

    # Enable a new domain
    push(@httpd_out, "Include /Applications/MAMP/conf/apache/$domain.conf\n");
    open HTTPD, ">" . HTTPD_CONF_DIR . "/httpd.conf";
    foreach (@httpd_out) {print HTTPD};
    close HTTPD;


    open DOMAIN_CONF, ">" . HTTPD_CONF_DIR . "/$domain.conf";
    print DOMAIN_CONF "<VirtualHost 127.0.0.1>
    ServerName $domain
    ServerAlias www.$domain
    VirtualDocumentRoot /Applications/MAMP/htdocs/$domain
</VirtualHost>";
    return "enabled";


}
