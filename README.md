Minecraft server runner
=======================

#Intro
This is a small collection of scripts, made to run a minecraft server, a little easier.
It runs the server in a screen, so it is possible to pipe commands to the server while its running.
This also means that having more then one detached screen as root can seriously break the functionality of this script.

**WARNING: This software so far runs on ONE server, and might be unstable.**


#Quick installation
> 1. Make sure you have all the dependencies installed and that you are root
> 2. Double check all the paths in the init and runner files. (or just put minecraft jar in /opt which is the default path)
> 3. Create the folder for backup. (f.x. /opt/backup)
> 4. Clone this git repository to your server. (f.x. into /opt)
> 5. Symlink the init script in init.d (ln -s /etc/init.d/minecraft /opt/mc-runner/minecraft-init.sh)
> 6. Install the init script (insserv /etc/init.d/minecraft)
> 7. Start the server with /etc/init.d/minecraft start
> 8. The server eather starts and all is good, or stuff will crash and hopefully error out


## Dependencies
Linux server (tested on Debian)
TONS of RAM, defaut setting is 6GB for the minecraft server
Perlsec::Helper - helper lib from http://github.com/perlsec/perl-helper
screen package - runs the java server in screen to keep ability to send commands to the server
java (oracle version 1.6 or 1.7)
minecraft jar
root & terminal on server
### Optional
c10t - for map generation extra features- http://toolchain.eu/project/c10t 
File::Tail perl package (debian package libfile-tail-perl) - For get-list.pl (userlist output script)

# Use
You can control the server via the init script or simply by attaching to the running screen for direct shell access.

## Extra features
There are some extra features in the script, for easy use, especially with a job in cron.

###Output list of online users
When the runner script is given the list command it will output a list of the users currently online to the log.
There is a helped script that will execute this, grab the output in the log, and then push it into a file for further use or posting on a website.
This means a simple command like this in cron will give you a up-to-date list of users on the server.
```bash
/opt/mc-runner/get-list.pl
```
(Dont use this too rapidly, only one process at a time can talk to the server. Every 3-5 minut is recommended)

###Backup world to external file
The runner script also has a backup function for easily setting up backups of the world

You use it by setting the right paths in the minecraft-runner.pl script and then sending the backup command to that script.
Again a good function to have in cron. It seems quite light-weight on the server, so can be run quite aggressively, like every hour or every fourth hour.
There are config options for how many backups to keep, default is 200. which is just over a months worth at 4 hour interval.
```bash
/opt/mc-runner/minecraft-runner.pl  backup
```

***BUGS: this backup function resets its counter on every server reboot AND keeps every version, so it will eventually fill your disk***

###Generate maps of the world

This function will generate two kinds of maps for your world.
An overview map and a 3d-ish map looking at the world at an angle.
This function requires the optional dependency c10t.
This library has to be compiled by hand for Debian linux as it is not a .deb file.

To use the function, set the config for it, and call the function via a cronscript.
Notice that this function can also keep a map archive, unless it is set to move the old versions to /dev/null.

The maps generated, will be called map.png for 3d-ish map and map-o.png for the overview map.

```bash
/opt/mc-runner/minecraft-runner.pl genmap
```

***WARNING: This function can be SUPER heavy on CPU and RAM as soon as the map becomes even slightly large. So run it when the players are not online.***
