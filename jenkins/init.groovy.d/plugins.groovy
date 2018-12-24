#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

instance.updateCenter.getPlugin("git").deploy();
instance.updateCenter.getPlugin("github").deploy();
instance.updateCenter.getPlugin("ssh").deploy();