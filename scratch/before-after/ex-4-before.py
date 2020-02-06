def replace(name):
    """Replaces a snapshot"""
    app = get_app()
    snapshot = app.get_snapshot(name)
    if not snapshot:
        click.echo("Couldn't find snapshot %s" % name)
        sys.exit(1)
    app.remove_snapshot(snapshot)
    app.create_snapshot(name)
    click.echo('Replaced snapshot %s' % name)
