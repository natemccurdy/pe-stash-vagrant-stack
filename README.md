# PE Stash Vagrant Stack

The stash-server VM is setup to install stash in developer mode which is a 24-hour license.  If you remove that flag you have to get an evaluation license key which will last 30 days.  You may want to do that if you have something long standing to test.

http://blogs.atlassian.com/2014/11/automating-stash-deployments/

You can reach the Stash UI on port 7990

username: admin
password: admin

The goal of the stack is to facilitate testing and understanding of how to use code-manager with stash.

The stack sets up a puppet master and a Stash server.

If you are attempting to replicate this setup here are the steps that you'll need to complete that this stack takes care of for you.

1. Add the Puppet Master's CA cert to the Java keystore on the Stash server:
  * Determine the $JAVA_HOME value used for Stash by looking in `opt/stash/atlassian-stash-3.11.6/bin/setenv.sh`. In my case, it's
    `/etc/alternatives/java_sdk`.
  * Run the following command and replace `$JAVA_HOME` with the path just determined:
    * `$JAVA_HOME/bin/keytool -import -alias tomcat -file /etc/puppetlabs/puppet/ssl/certs/ca.pem -keystore $JAVA_HOME/jre/lib/security/cacerts`
    * When asked for a password, use `changeit`.
  * I've done all this automatically with the Puppet code at:

The final steps to setup the post receive hook are manual.

1. Install the following stash plugin
  * https://marketplace.atlassian.com/plugins/com.atlassian.stash.plugin.stash-web-post-receive-hooks-plugin/server/overview
1.  Make sure your ssh key is setup for root on the puppet master and you've configured it for your stash user
  * https://confluence.atlassian.com/display/STASH/SSH+user+keys+for+personal+use
1. Configure a post-receive hook on your control repo
  * https://confluence.atlassian.com/display/STASH/Using+repository+hooks
  * The command to run is:
    * `/opt/puppet/sbin/stash_mco.rb -k -t https://puppet:puppet@puppet-master:8088/payload`


## Other Notes

This is based on the puppet-debugging-kit.

https://github.com/Sharpie/puppet-debugging-kit
