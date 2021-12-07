# frozen_string_literal: true

class VACOLS::DecisionQualityReview < VACOLS::Record
  self.table_name = "qrdecs"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: qrdecs
#
#  qrfolder  :string(12)       not null, indexed
#  qrseldate :date             not null
#  qrsmem    :string(4)        not null, indexed
#  qrteam    :string(2)
#  qryymm    :string(4)        not null, indexed
#
