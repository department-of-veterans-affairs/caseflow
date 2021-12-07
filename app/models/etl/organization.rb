# frozen_string_literal: true

# copy of Organization model

class ETL::Organization < ETL::Record
  self.inheritance_column = :_type_disabled # no STI on ETL
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: organizations
#
#  id                            :bigint           not null, primary key
#  accepts_priority_pushed_cases :boolean          indexed
#  ama_only_push                 :boolean          default(FALSE)
#  ama_only_request              :boolean          default(FALSE)
#  name                          :string
#  role                          :string
#  status                        :string           default("active"), indexed
#  status_updated_at             :datetime
#  type                          :string
#  url                           :string           indexed
#  created_at                    :datetime         indexed
#  updated_at                    :datetime         indexed
#  participant_id                :string
#
