# frozen_string_literal: true

# copy of Person model

class ETL::Person < ETL::Record
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: people
#
#  id             :bigint           not null, primary key
#  date_of_birth  :date
#  email_address  :string
#  first_name     :string(50)
#  last_name      :string(50)
#  middle_name    :string(50)
#  name_suffix    :string(20)
#  ssn            :string           indexed
#  created_at     :datetime         not null, indexed
#  updated_at     :datetime         not null, indexed
#  participant_id :string(50)       not null, indexed
#
