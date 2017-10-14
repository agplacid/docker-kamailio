from invoke import task, call
from . import dc


@task(default=True, pre=[call(dc.launch)])
def docker(ctx):
    ctx.run('sleep 15')
    result = ctx.run('tests/run', pty=True)
    dc.down(ctx)
    exit(result.exited)
