class DocumentsTag < ApplicationRecord
  belongs_to :document
  belongs_to :tag
end
