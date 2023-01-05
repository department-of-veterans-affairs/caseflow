# frozen_string_literal: true

# bundle exec rails runner scripts/add_corres_for_stmdtime_testing.rb

# creates data in local VACOLS for testing update_vacols_stmdtime_from_caseflow.rb script
# 7000 MpiUpdatePersonEvent records are created
# 6000 CORRES records are created
# 3000 of the CORRES records should be updated (STAFKEY ending in 0001-1000, 1001-2000, 3001-4000)
# 2000 of the CORRES records have STMDTIME that is more recent than the MpiUpdatePersonEvent.completed_at
# 1000 of the CORRES records have MpiUpdatePersonEvent that did not result in an update occurring

@deceased_time = 1.year.ago.to_date
@stafkey = 110_000_000
@api_key = ApiKey.find_or_create_by(consumer_name: "STMDTIME testing")

def api_key
  @api_key
end

def stafkey
  @stafkey += 1
  format("%<n>09d", n: @stafkey)
end

def ssn
  Generators::Random.unique_ssn
end

def corres_nil_stmdtime
  # CORRES record with update event and nil STMDTIME
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", sfnod: @deceased_time)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time,
    updated_column: "deceased_time",
    updated_deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "successful")
end

def corres_stmdtime_older_than_update_event
  # CORRES record with old STMDTIME
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", stmdtime: 2.years.ago.to_date, sfnod: @deceased_time)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time,
    updated_column: "deceased_time",
    updated_deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "successful")
end

def corres_stmdtime_newer_than_update_event
  # CORRES record with STMDTIME 1 day from now
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", stmdtime: 1.month.from_now.to_date, sfnod: @deceased_time)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time,
    updated_column: "deceased_time",
    updated_deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "successful")
end

def corres_stmdtime_older_than_update_event_type_updated
  # CORRES record with old STMDTIME
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", stmdtime: 2.years.ago.to_date, sfnod: @deceased_time)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time,
    updated_column: "deceased_time",
    updated_deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "already_deceased")
end

def corres_stmdtime_newer_than_update_event_type_updated
  # CORRES record with old STMDTIME
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", stmdtime: 1.month.from_now.to_date, sfnod: @deceased_time)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time,
    updated_column: "deceased_time",
    updated_deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "already_deceased")
end

def corres_with_sfnod_event_type_not_updated
  # CORRES record with SFNOD that was not updated
  corres = FactoryBot.create(:correspondent, stafkey: stafkey, ssn: ssn, stmduser: "SEED", sfnod: @deceased_time, stmdtime: 1.year.ago.to_date)

  info = {
    veteran_ssn: corres.ssn,
    veteran_pat: corres.stafkey,
    deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "already_deceased")
end

def mpi_update_person_event_no_veteran
  info = {
    veteran_ssn: ssn,
    veteran_pat: stafkey,
    deceased_time: @deceased_time
  }
  MpiUpdatePersonEvent.create(api_key_id: api_key.id, completed_at: Time.zone.now, info: info, update_type: "no_veteran")
end

1000.times { corres_nil_stmdtime }
1000.times { corres_stmdtime_older_than_update_event }
1000.times { corres_stmdtime_newer_than_update_event }
1000.times { corres_stmdtime_older_than_update_event_type_updated }
1000.times { corres_stmdtime_newer_than_update_event_type_updated }
1000.times { corres_with_sfnod_event_type_not_updated }
1000.times { mpi_update_person_event_no_veteran }
