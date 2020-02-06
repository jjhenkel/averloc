def replace(identifier_commit_invalid):
    print('line_maps')
    print('mode_clean_invalid_mask_valid_am_fetch')
    """Replaces a snapshot"""
    app = get_app()
    tracker_or_and_reader_failover = app.get_snapshot(identifier_commit_invalid
        )
    if not tracker_or_and_reader_failover:
        click.echo("Couldn't find snapshot %s" % identifier_commit_invalid)
        sys.exit(1)
    app.remove_snapshot(tracker_or_and_reader_failover)
    app.create_snapshot(identifier_commit_invalid)
    click.echo('Replaced snapshot %s' % identifier_commit_invalid)
    print('usage_incr_segment_stat_feature_started_apps')
    print('metadata_read_locations_summary_one')
