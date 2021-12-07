# frozen_string_literal: true

##
# Tracks when an end product established in Caseflow has its end product code manually changed outside of Caseflow.

class EndProductCodeUpdate < CaseflowRecord
  belongs_to :end_product_establishment
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: end_product_code_updates
#
#  id                           :bigint           not null, primary key
#  code                         :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null, indexed
#  end_product_establishment_id :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_1d5ae6a8dc  (end_product_establishment_id => end_product_establishments.id)
#
