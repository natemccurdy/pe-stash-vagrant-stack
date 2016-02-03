# PE Stash Vagrant Stack

The stash-server VM is setup to install stash in developer mode which is a 24-hour license.  If you remove that flag you have to get an evaluation license key which will last 30 days.  You may want to do that if you have something long standing to test.

http://blogs.atlassian.com/2014/11/automating-stash-deployments/

You can reach the Stash UI on port 7990

username: admin
password: admin

The goal of the stack is to facilitate testing and understanding of how to use code-manager with stash.

The stack sets up a PE 2015.3.x puppet master and a Stash server.

If you are attempting to replicate this setup, here are the steps that you would need to complete manually (but that this stack takes care of for you).

1. Create an RBAC user on the Puppet master and generate an auth token to be used by the webhook.
  * https://docs.puppetlabs.com/pe/latest/code_mgr_webhook.html#generate-an-authentication-token
  * I've done this automatically with the puppet code in: site/profile/manifests/code_manager.pp
1. Add the Puppet Master's CA cert to the Java keystore on the Stash server:
  * Determine the $JAVA_HOME value used for Stash by looking in `opt/stash/atlassian-stash-3.11.6/bin/setenv.sh`. In my case, it's
    `/etc/alternatives/java_sdk`.
  * Run the following command and replace `$JAVA_HOME` with the path just determined:
    * `$JAVA_HOME/bin/keytool -import -alias tomcat -file /etc/puppetlabs/puppet/ssl/certs/ca.pem -keystore $JAVA_HOME/jre/lib/security/cacerts`
    * When asked for a password, use `changeit`.
  * I've done all this automatically with the Puppet code at: site/profile/manifests/stash_server/pp:34

The final steps to setup the post receive hook are manual.

1. Install the following stash plugin by logging into the web GUI of the Stash server and going to `Find new add-ons`.
  * https://marketplace.atlassian.com/plugins/com.atlassian.stash.plugin.stash-web-post-receive-hooks-plugin/server/overview
1. Make a `Project` and a blank `repository` inside that project
  * I recommend a project called `puppet` and a repository called `control-repo`
1. Configure a hook on your control repo.
  * Click the `Hooks` tab under the repo's settings.
  * Click the pencil icon next to `Post-Receive WebHooks`
  * The URL to drop in should be in the format of:
    * `https://puppet-master:8170/code-manager/v1/webhook?type=stash&token=<TOKEN>`
    * Replace \<TOKEN\> with the RBAC Token that was generated automatically for you.
      * The token value can be found on the puppet master in a file at: `/vagrant/code_manager_rbac_token`


## Other Notes

This is based on the puppet-debugging-kit.

https://github.com/Sharpie/puppet-debugging-kit
