drop trigger if exists update_claim_status_trigger on vbms_ext_claim;

create or replace function public.update_claim_status_trigger_function()
returns trigger as $$
	declare
		string_claim_id varchar(25);
		epe_id integer;
	begin
		if (NEW."EP_CODE" LIKE '04%'
				OR NEW."EP_CODE" LIKE '03%'
				OR NEW."EP_CODE" LIKE '93%'
				OR NEW."EP_CODE" LIKE '68%')
				and (NEW."LEVEL_STATUS_CODE" = 'CLR' OR NEW."LEVEL_STATUS_CODE" = 'CAN') then

			string_claim_id := cast(NEW."CLAIM_ID" as varchar);

			select id into epe_id
			from end_product_establishments
			where (reference_id = string_claim_id
			and (synced_status is null or synced_status <> NEW."LEVEL_STATUS_CODE"));

			if epe_id > 0
			then
				if not exists (
					select 1
					from priority_end_product_sync_queue
					where end_product_establishment_id = epe_id
				) then
					insert into priority_end_product_sync_queue (created_at, end_product_establishment_id, updated_at)
					values (now(), epe_id, now());
				end if;
			end if;
		end if;
		return null;
	end;
$$
language plpgsql;

create trigger update_claim_status_trigger
after update or insert on vbms_ext_claim
for each row
execute procedure public.update_claim_status_trigger_function();
