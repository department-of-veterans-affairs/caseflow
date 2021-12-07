# frozen_string_literal: true

##
# JudgeSchedulePeriod represents a schedule period for assigning judges to hearing days.
# This record is created after user uploads JudgeAssignment spreadsheet for a schedule period.
# Once created, it creates JudgeNonAvailability records with the blackout dates for each judge.
#
# This class is no longer used, but preserved here to make it easier to access historical database records.
##
class JudgeSchedulePeriod < SchedulePeriod; end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: schedule_periods
#
#  id         :bigint           not null, primary key
#  end_date   :date             not null
#  file_name  :string           not null
#  finalized  :boolean
#  start_date :date             not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null, indexed
#  user_id    :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_4e80f1285a  (user_id => users.id)
#
