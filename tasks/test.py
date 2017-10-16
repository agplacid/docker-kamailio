from invoke import task #, call
# from . import dc
#
#
# @task(default=True, pre=[call(dc.launch)])
# def docker(ctx):
#     ctx.run('sleep 15')
#     result = ctx.run('tests/run', pty=True)
#     dc.down(ctx)
#     exit(result.exited)

@task(default=True)
def run(ctx, service=None):
    services = [service] if service else ctx.docker.services
    for service in services:
        print('testing {}'.format(service))
        ctx.run('tests/run {}'.format(service), pty=True)


@task
def edit(ctx, service=None):
    services = [service] if service else ctx.docker.services
    for service in services:
        print('editing test for {}'.format(service))
        ctx.run('tests/edit {}'.format(service), pty=True)
