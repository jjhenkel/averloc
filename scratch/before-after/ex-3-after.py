def delete_record(scheme_job_scheduler, response_master_running_report_args):
    """Delete a record and it's persistent identifiers."""
    response_master_running_report_args.delete()
    PersistentIdentifier.query.filter_by(object_type='rec', object_uuid=
        response_master_running_report_args.id).update({
        PersistentIdentifier.status: PIDStatus.DELETED})
    scheme_job_scheduler.delete_buckets(response_master_running_report_args)
    db.session.commit()
