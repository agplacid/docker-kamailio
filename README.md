# Kamailio

Kamailio, for use in a kubernetes pod.


## Issues

### Docker.hub automated builds don't tolerate COPY or ADD to root /

I've added a comment to the Dockerfile noting this and for now am copying to
/tmp and then copying to / in the next statement.

ref: https://forums.docker.com/t/automated-docker-build-fails/22831/28

### Docker has problems setting realtime priority: SCHED_FIFO

This is a well known problem and the only way to fix it is nearly impossible
to automate.

ref: http://www.breakage.org/2014/08/22/using-sched_fifo-in-docker-containers-on-rhel/

Rather low priority issue for now I think.
