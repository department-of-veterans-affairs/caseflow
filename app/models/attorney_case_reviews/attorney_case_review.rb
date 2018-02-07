class AttorneyCaseReview < ActiveRecord::Base
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"
end
