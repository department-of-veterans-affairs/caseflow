create or replace function caseflow_audit.add_row_to_appeal_states_audit() returns trigger
as
$add_row$
begin
  if (TG_OP = 'DELETE') then
    insert into caseflow_audit.appeal_states_audit
    select
      nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
      'D',
      OLD.id,
      OLD.appeal_cancelled,
      OLD.appeal_docketed,
      OLD.appeal_id,
      OLD.appeal_type,
      OLD.created_at,
      OLD.created_by_id,
      OLD.decision_mailed,
      OLD.hearing_postponed,
      OLD.hearing_scheduled,
      OLD.hearing_withdrawn,
      OLD.privacy_act_complete,
      OLD.privacy_act_pending,
      OLD.scheduled_in_error,
      OLD.updated_at,
      OLD.updated_by_id,
      OLD.vso_ihp_complete,
      OLD.vso_ihp_pending;
  elsif (TG_OP = 'UPDATE') then
    insert into caseflow_audit.appeal_states_audit
    select
      nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
      'U',
      NEW.id,
      NEW.appeal_cancelled,
      NEW.appeal_docketed,
      NEW.appeal_id,
      NEW.appeal_type,
      NEW.created_at,
      NEW.created_by_id,
      NEW.decision_mailed,
      NEW.hearing_postponed,
      NEW.hearing_scheduled,
      NEW.hearing_withdrawn,
      NEW.privacy_act_complete,
      NEW.privacy_act_pending,
      NEW.scheduled_in_error,
      NEW.updated_at,
      NEW.updated_by_id,
      NEW.vso_ihp_complete,
      NEW.vso_ihp_pending;
  elsif (TG_OP = 'INSERT') then
    insert into caseflow_audit.appeal_states_audit
    select
      nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
      'I',
      NEW.id,
      NEW.appeal_cancelled,
      NEW.appeal_docketed,
      NEW.appeal_id,
      NEW.appeal_type,
      NEW.created_at,
      NEW.created_by_id,
      NEW.decision_mailed,
      NEW.hearing_postponed,
      NEW.hearing_scheduled,
      NEW.hearing_withdrawn,
      NEW.privacy_act_complete,
      NEW.privacy_act_pending,
      NEW.scheduled_in_error,
      NEW.updated_at,
      NEW.updated_by_id,
      NEW.vso_ihp_complete,
      NEW.vso_ihp_pending;
  end if;
  return null;
end;
$add_row$
language plpgsql;
