def delete_record(cls, record):
    """Delete a record and it's persistent identifiers."""
    record.delete()
    PersistentIdentifier.query.filter_by(object_type='rec', object_uuid=
        record.id).update({PersistentIdentifier.status: PIDStatus.DELETED})
    cls.delete_buckets(record)
    db.session.commit()