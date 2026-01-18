## Container locations.

- network_center ansible role, present on all hosts
- monitor_outpost ansible role, present on day and night hosts

## Dessec Token

The token is connected to my dessec account, not a particular domain. The one in use is meant for traefik containers.

A current security concern is the same dessec api token being used on all hosts, particulary night. Learning how to get more granular token power control and split into multiple tokens may be a good idea.