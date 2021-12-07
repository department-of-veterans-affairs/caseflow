# frozen_string_literal: true

# transformed User model, with VACOLS+Caseflow attributes

class ETL::User < ETL::Record
  class << self
    def origin_primary_key
      :user_id
    end

    private

    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      target.created_at = original.created_at || original.vacols_user&.created_at

      target.user_id = original.id
      target.css_id = original.css_id
      target.email = original.email
      target.full_name = original.full_name
      target.last_login_at = original.last_login_at
      target.roles = original.roles
      target.selected_regional_office = original.selected_regional_office
      target.station_id = original.station_id
      target.status = original.status
      target.status_updated_at = original.status_updated_at

      # not all users are in VACOLS.
      return target if original.vacols_user.blank?

      target.sactive = original.vacols_user.sactive
      target.slogid = original.vacols_user.slogid
      target.stafkey = original.vacols_user.stafkey
      target.svlj = original.vacols_user.svlj
      target.stitle = original.vacols_user.stitle
      target.smemgrp = original.vacols_user.smemgrp
      target.sattyid = original.vacols_user.sattyid

      target
    end
    # rubocop:enable Metrics/AbcSize
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  email                    :string(255)
#  full_name                :string(255)
#  last_login_at            :datetime
#  roles                    :string           is an Array
#  sactive                  :string(1)
#  sattyid                  :string(20)
#  selected_regional_office :string(255)
#  slogid                   :string(20)
#  smemgrp                  :string(8)
#  stafkey                  :string(20)
#  status                   :string(20)       default("active"), indexed
#  status_updated_at        :datetime
#  stitle                   :string(16)
#  svlj                     :string(1)
#  created_at               :datetime         not null, indexed
#  updated_at               :datetime         not null, indexed
#  css_id                   :string(50)       not null
#  station_id               :string(20)       not null
#  user_id                  :integer          not null, indexed
#
