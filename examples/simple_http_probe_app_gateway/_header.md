#Application Gateway monitors the health probes

Azure Application Gateway monitors the health of all the servers in its backend pool and automatically stops sending traffic to any server it considers unhealthy. The probes continue to monitor such an unhealthy server, and the gateway starts routing the traffic to it once again as soon as the probes detect it as healthy.

# Default example

This deploys the module in its simplest form.
