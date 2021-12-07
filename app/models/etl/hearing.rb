# frozen_string_literal: true

# AMA hearings

class ETL::Hearing < ETL::HearingRecord
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: hearings
#
#  id                                    :bigint           not null, primary key
#  bva_poc                               :string
#  created_by_user_full_name             :string(255)
#  created_by_user_sattyid               :string(20)
#  disposition                           :string
#  evidence_window_waived                :boolean
#  hearing_created_at                    :datetime         indexed
#  hearing_day_bva_poc                   :string
#  hearing_day_created_at                :datetime         indexed
#  hearing_day_created_by_user_full_name :string(255)
#  hearing_day_created_by_user_sattyid   :string(20)
#  hearing_day_deleted_at                :datetime         indexed
#  hearing_day_lock                      :boolean
#  hearing_day_notes                     :text
#  hearing_day_regional_office           :string
#  hearing_day_request_type              :string
#  hearing_day_room                      :string
#  hearing_day_scheduled_for             :date
#  hearing_day_updated_at                :datetime         indexed
#  hearing_day_updated_by_user_full_name :string(255)
#  hearing_day_updated_by_user_sattyid   :string(20)
#  hearing_location_address              :string
#  hearing_location_city                 :string
#  hearing_location_classification       :string
#  hearing_location_created_at           :datetime         indexed
#  hearing_location_distance             :float
#  hearing_location_facility_type        :string
#  hearing_location_name                 :string
#  hearing_location_state                :string
#  hearing_location_updated_at           :datetime         indexed
#  hearing_location_zip_code             :string
#  hearing_request_type                  :string           not null, indexed
#  hearing_updated_at                    :datetime         indexed
#  judge_full_name                       :string
#  judge_sattyid                         :string
#  military_service                      :string
#  notes                                 :string
#  prepped                               :boolean
#  representative_name                   :string
#  room                                  :string
#  scheduled_time                        :time
#  summary                               :text
#  transcript_requested                  :boolean
#  transcript_sent_date                  :date
#  type                                  :string           indexed
#  updated_by_user_full_name             :string(255)
#  updated_by_user_sattyid               :string(20)
#  uuid                                  :uuid             indexed
#  witness                               :string
#  created_at                            :datetime         not null, indexed
#  updated_at                            :datetime         not null, indexed
#  appeal_id                             :integer          not null, indexed
#  created_by_id                         :bigint
#  created_by_user_css_id                :string(50)
#  hearing_day_created_by_id             :bigint
#  hearing_day_created_by_user_css_id    :string(50)
#  hearing_day_id                        :integer          indexed
#  hearing_day_judge_id                  :integer
#  hearing_day_updated_by_id             :bigint
#  hearing_day_updated_by_user_css_id    :string(50)
#  hearing_id                            :bigint           not null, indexed
#  hearing_location_facility_id          :string
#  hearing_location_id                   :bigint           indexed
#  judge_css_id                          :string
#  judge_id                              :integer          indexed
#  updated_by_id                         :bigint
#  updated_by_user_css_id                :string(50)
#  vacols_id                             :string           indexed
#
