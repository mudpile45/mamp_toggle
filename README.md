mamp_toggle
===========
This is a simple perl utility to toggle apache virtualhosts and your hosts
files in MAMP to allow for at home development.

This allows you to redirect any domain you specify to a folder on your computer
and provides an easy way to return to the original domain when your development
is finished.

For now, this is only useful if you: 
* develop web applications locally on a mac and using MAMP

# Usage

1. Put the script somewhere on your path
2. Run it with a domain name **(don't include the www!)**, e.g. `webdevtoggle.pl mydomain.com`
3. Restart MAMP (if it's already running)

That's it. 

Now if you go to mydomain.com you will be redirected the
/Applications/MAMP/htdocs/mydomain.com folder on your local machine. (so make
sure you put your site there!) 

When you're done developing and want to be able to access the real website
simply run the command again: `webdevtoggle.pl mydomain.com`

# Command line options
You can use -e and -d switches for enable and disable respectively if you want
to ensure that an alias is in a certain state. Default behavior is to check the
status of your config files and toggle.

# How it works
All it does is check if your hosts file has an entry for the domain you specify
on the command line.

If it exists then it is removed.

Then it checks in your /Applications/MAMP/conf/ directory and if no existing
vhost for your domain exists it creates one in a separate file and appends an
include file directive to MAMP's existing httpd.conf

When you run it again if a vhost file is found then it and it's corresponding
include file directive in httpd.conf are removed.
