class DocumentsTag < ActiveRecord::Base
  belongs_to :document
  belongs_to :tag
end
