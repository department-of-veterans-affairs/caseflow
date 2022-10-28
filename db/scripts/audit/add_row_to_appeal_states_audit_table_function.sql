create or replace function caseflow_audit.add_row_to_appeal_states_audit() returns trigger 
	as 
	$appeal_states_audit$
	begin 
		if (TG_OP = 'DELETE') then
			insert into caseflow_audit.appeal_states_audit select 'D', now(), user, OLD.*;
		elsif (TG_OP = 'UPDATE') then
        -- this should be new, I think
			insert into caseflow_audit.appeal_states_audit select 'U', now(), user, NEW.*;
		elsif (TG_OP = 'INSERT') then
			insert into caseflow_audit.appeal_states_audit select 'I', now(), user, NEW.*;
		end if;
		return null;
	end;
	$appeal_states_audit$
	language plpgsql;
	