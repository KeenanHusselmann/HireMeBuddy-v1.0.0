# Migration Renumbering Plan

## Analysis Summary
- **Total migrations**: 70 files
- **Duplicate numbers**: 14 conflicts
- **Corrupt files**: 1 (012_fix_admin_provider_policies.sql - 1 byte)
- **Unnumbered**: 2 valid migrations
- **Debug/Temp files**: 3 to remove
- **Obsolete (050-055)**: 6 to remove or archive

## PROPOSED NEW NUMBERING SCHEME

### Keep As-Is (No Conflicts):
- 001_initial_schema.sql ✅
- 016_add_first_last_name.sql ✅
- 017_add_verification_documents.sql ✅
- 018_notify_admin_new_provider.sql ✅
- 019_backfill_provider_notifications.sql ✅
- 020_fix_storage_policies.sql ✅
- 021_sync_emails_to_profiles.sql ✅
- 022_add_booking_details_fields.sql ✅
- 023_add_job_completion_fields.sql ✅
- 024_fix_booking_cancellation_rls.sql ✅
- 026_enable_rls_notification_queue.sql ✅
- 027_fcm_notification_triggers.sql ✅
- 028_fix_fcm_immediate_send.sql ✅
- 030_fix_message_trigger.sql ✅
- 031_attach_booking_status_trigger.sql ✅
- 033_fix_confirmed_status.sql ✅
- 034_device_token_cleanup.sql ✅
- 036_configure_fcm_cron.sql ✅
- 037_fix_fcm_cron_no_settings.sql ✅
- 038_optimize_rls_comprehensive.sql ✅
- 056_rollback_migration_050.sql ✅ (CRITICAL - Already applied)
- 057_fix_trigger_functions_after_rls_reset.sql ✅
- 058_ensure_notification_tables_exist.sql ✅
- 059_recreate_notification_triggers.sql ✅
- 060_drop_broken_notification_trigger.sql ✅
- 062_enable_fcm_cron_job.sql ✅
- 063_fix_device_tokens_rls_for_security_definer.sql ✅ (Already applied)
- 064_recreate_send_fcm_notification.sql ✅ (Already applied)
- 065_drop_broken_trigger.sql ✅ (Already applied)
- 066_fix_notify_new_message.sql ✅ (Already applied)
- 067_instant_notifications.sql ✅ (Already applied)

### Renumber Duplicates (002-015):

| Old Name | New Number | New Name |
|----------|-----------|----------|
| 002_rls_policies.sql | 002 | 002_rls_policies.sql |
| 002_create_chat_messages.sql | 003 | 003_create_chat_messages.sql |
| 003_seed_data.sql | 004 | 004_seed_data.sql |
| 003_add_total_reviews.sql | 005 | 005_add_total_reviews.sql |
| 004_update_messages_table.sql | 006 | 006_update_messages_table.sql |
| 004_fix_notifications_column.sql | 007 | 007_fix_notifications_column.sql |
| 005_update_messages_rls.sql | 008 | 008_update_messages_rls.sql |
| 005_fix_notifications_table_structure.sql | 009 | 009_fix_notifications_table_structure.sql |
| 006_add_more_categories.sql | 010 | 010_add_more_categories.sql |
| 006_fix_notifications_rls.sql | 011 | 011_fix_notifications_rls.sql |
| 007_fix_provider_services_constraints.sql | 012 | 012_fix_provider_services_constraints.sql |
| 007_diagnose_notifications.sql | DELETE | (Debug only - remove) |
| 008_update_provider_services_schema.sql | 013 | 013_update_provider_services_schema.sql |
| 008_create_send_notification_function.sql | 014 | 014_create_send_notification_function.sql |
| 009_create_portfolio_images.sql | 015 | 015_create_portfolio_images.sql |
| 009_add_notification_enum_values.sql | 016 | 016_add_notification_enum_values.sql |
| 010_update_completed_jobs_count.sql | 017 | 017_update_completed_jobs_count.sql |
| 010_add_portfolio_media_types.sql | 018 | 018_add_portfolio_media_types.sql |
| 011_update_portfolio_bucket_for_videos.sql | 019 | 019_update_portfolio_bucket_for_videos.sql |
| 011_create_admin_notifications.sql | 020 | 020_create_admin_notifications.sql |
| 012_add_contact_fields_to_profiles.sql | 021 | 021_add_contact_fields_to_profiles.sql |
| 012_add_contact_number_to_provider_profiles.sql | 022 | 022_add_contact_number_to_provider_profiles.sql |
| 012_fix_admin_provider_policies.sql | DELETE | (Corrupt - 1 byte file) |
| 013_populate_email_from_auth.sql | 023 | 023_populate_email_from_auth.sql |
| 013_admin_select_provider_profiles.sql | 024 | 024_admin_select_provider_profiles.sql |
| 014_fix_total_jobs_function.sql | 025 | 025_fix_total_jobs_function.sql |

### Renumber 016+ (Shift down due to deletions):

| Old Name | New Number | New Name |
|----------|-----------|----------|
| 016_add_first_last_name.sql | 026 | 026_add_first_last_name.sql |
| 017_add_verification_documents.sql | 027 | 027_add_verification_documents.sql |
| 018_notify_admin_new_provider.sql | 028 | 028_notify_admin_new_provider.sql |
| 019_backfill_provider_notifications.sql | 029 | 029_backfill_provider_notifications.sql |
| 020_fix_storage_policies.sql | 030 | 030_fix_storage_policies.sql |
| 021_sync_emails_to_profiles.sql | 031 | 031_sync_emails_to_profiles.sql |
| 022_add_booking_details_fields.sql | 032 | 032_add_booking_details_fields.sql |
| 023_add_job_completion_fields.sql | 033 | 033_add_job_completion_fields.sql |
| 024_fix_booking_cancellation_rls.sql | 034 | 034_fix_booking_cancellation_rls.sql |

### Renumber 025 (3-way conflict):

| Old Name | New Number | New Name |
|----------|-----------|----------|
| 025_fix_phone_validation.sql | 035 | 035_fix_phone_validation.sql |
| 025_make_phone_required_for_clients.sql | 036 | 036_make_phone_required_for_clients.sql |
| 025_optimize_rls_performance.sql | 037 | 037_optimize_rls_performance.sql |

### Renumber 026+:

| Old Name | New Number | New Name |
|----------|-----------|----------|
| 026_enable_rls_notification_queue.sql | 038 | 038_enable_rls_notification_queue.sql |
| 027_fcm_notification_triggers.sql | 039 | 039_fcm_notification_triggers.sql |
| 028_fix_fcm_immediate_send.sql | 040 | 040_fix_fcm_immediate_send.sql |
| 029_fix_authorization_header.sql | 041 | 041_fix_authorization_header.sql |
| 029_setup_fcm_cron_job.sql | 042 | 042_setup_fcm_cron_job.sql |
| 030_fix_message_trigger.sql | 043 | 043_fix_message_trigger.sql |
| 031_attach_booking_status_trigger.sql | 044 | 044_attach_booking_status_trigger.sql |
| 032_add_trigger_debug_logging.sql | DELETE | (Debug only - remove) |
| 033_fix_confirmed_status.sql | 045 | 045_fix_confirmed_status.sql |
| 034_device_token_cleanup.sql | 046 | 046_device_token_cleanup.sql |
| 036_configure_fcm_cron.sql | 047 | 047_configure_fcm_cron.sql |
| 037_fix_fcm_cron_no_settings.sql | 048 | 048_fix_fcm_cron_no_settings.sql |
| 038_optimize_rls_comprehensive.sql | 049 | 049_optimize_rls_comprehensive.sql |

### Archive Broken Migrations (050-055):

| Old Name | Action | Location |
|----------|--------|----------|
| 050_optimize_rls_performance.sql | ARCHIVE | docs/archived_migrations/ |
| 051_cleanup_remaining_policies.sql | ARCHIVE | docs/archived_migrations/ |
| 052_fix_modify_policy_conflicts.sql | ARCHIVE | docs/archived_migrations/ |
| 053_enable_rls_cron_secrets.sql | ARCHIVE | docs/archived_migrations/ |
| 054_secure_function_search_paths.sql | ARCHIVE | docs/archived_migrations/ |
| 055_fix_infinite_recursion_hotfix.sql | ARCHIVE | docs/archived_migrations/ |

**Note**: Keep 056 as rollback reference - DO NOT RENUMBER

### Renumber 056+ (Already applied - keep high numbers):

| Old Name | New Number | New Name |
|----------|-----------|----------|
| 056_rollback_migration_050.sql | 050 | 050_rollback_migration_050.sql |
| 057_fix_trigger_functions_after_rls_reset.sql | 051 | 051_fix_trigger_functions_after_rls_reset.sql |
| 058_ensure_notification_tables_exist.sql | 052 | 052_ensure_notification_tables_exist.sql |
| 059_recreate_notification_triggers.sql | 053 | 053_recreate_notification_triggers.sql |
| 060_drop_broken_notification_trigger.sql | 054 | 054_drop_broken_notification_trigger.sql |
| 061_temporarily_disable_messages_rls.sql | DELETE | (Temporary fix - remove) |
| 062_enable_fcm_cron_job.sql | 055 | 055_enable_fcm_cron_job.sql |
| 063_fix_device_tokens_rls_for_security_definer.sql | 056 | 056_fix_device_tokens_rls_for_security_definer.sql |
| 064_recreate_send_fcm_notification.sql | 057 | 057_recreate_send_fcm_notification.sql |
| 065_drop_broken_trigger.sql | 058 | 058_drop_broken_trigger.sql |
| 066_fix_notify_new_message.sql | 059 | 059_fix_notify_new_message.sql |
| 067_instant_notifications.sql | 060 | 060_instant_notifications.sql |

### Add Unnumbered Migrations:

| Old Name | New Number | New Name |
|----------|-----------|----------|
| add_provider_services_constraints.sql | 061 | 061_add_provider_services_constraints.sql |
| create_waiting_list.sql | 062 | 062_create_waiting_list.sql |

## FILES TO DELETE (5 total):
1. `007_diagnose_notifications.sql` - Debug only
2. `012_fix_admin_provider_policies.sql` - Corrupt (1 byte)
3. `032_add_trigger_debug_logging.sql` - Debug only
4. `061_temporarily_disable_messages_rls.sql` - Temporary workaround

## FILES TO ARCHIVE (6 total):
Move to `docs/archived_migrations/broken_050_series/`:
1. `050_optimize_rls_performance.sql` - Caused infinite recursion
2. `051_cleanup_remaining_policies.sql` - Fix attempt
3. `052_fix_modify_policy_conflicts.sql` - Fix attempt
4. `053_enable_rls_cron_secrets.sql` - Fix attempt
5. `054_secure_function_search_paths.sql` - Fix attempt
6. `055_fix_infinite_recursion_hotfix.sql` - Failed hotfix

## FINAL RESULT:
- **Current**: 70 files (with duplicates and broken)
- **After cleanup**: 62 files (sequential 001-062)
- **Deleted**: 4 files
- **Archived**: 6 files

## EXECUTION STEPS:
1. Create archive folder
2. Move broken 050-055 series to archive
3. Delete debug/corrupt files
4. Rename files in reverse order (062 → 001) to avoid conflicts
5. Verify sequential numbering
6. Update any migration tracking tables in Supabase
