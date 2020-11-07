ALTER TABLE dms_sample.player
DROP CONSTRAINT IF EXISTS sport_team_fk;

ALTER TABLE dms_sample.seat
DROP CONSTRAINT IF EXISTS seat_type_fk;

ALTER TABLE dms_sample.sport_division
DROP CONSTRAINT IF EXISTS sd_sport_type_fk;

ALTER TABLE dms_sample.sport_division 
DROP CONSTRAINT IF EXISTS sd_sport_league_fk;

ALTER TABLE dms_sample.sport_league 
DROP CONSTRAINT IF EXISTS sl_sport_type_fk;

ALTER TABLE dms_sample.sport_team 
DROP CONSTRAINT IF EXISTS st_sport_type_fk;

ALTER TABLE dms_sample.sport_team 
DROP CONSTRAINT IF EXISTS home_field_fk;

ALTER TABLE dms_sample.sporting_event
DROP CONSTRAINT IF EXISTS se_sport_type_fk;

ALTER TABLE dms_sample.sporting_event 
DROP CONSTRAINT IF EXISTS se_away_team_id_fk;

ALTER TABLE dms_sample.sporting_event 
DROP CONSTRAINT IF EXISTS se_home_team_id_fk;

ALTER TABLE dms_sample.sporting_event_ticket 
DROP CONSTRAINT IF EXISTS set_person_id;

ALTER TABLE dms_sample.sporting_event_ticket 
DROP CONSTRAINT IF EXISTS set_sporting_event_fk;

ALTER TABLE dms_sample.sporting_event_ticket 
DROP CONSTRAINT IF EXISTS set_seat_fk;

ALTER TABLE dms_sample.ticket_purchase_hist 
DROP CONSTRAINT IF EXISTS tph_sport_event_tic_id;

ALTER TABLE dms_sample.ticket_purchase_hist 
DROP CONSTRAINT IF EXISTS tph_ticketholder_id;

ALTER TABLE dms_sample.ticket_purchase_hist 
DROP CONSTRAINT IF EXISTS tph_transfer_from_id;