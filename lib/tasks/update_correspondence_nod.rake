# frozen_string_literal: true

namespace :correspondence do
  desc "Update nod column of correspondences table according to name of package_document_types table"

  task update_nod: [:environment] do
    correspondences = Correspondence.includes(:package_document_type)
    correspondences.each do |correspondence|
      correspondence.nod = false
      if correspondence.package_document_type && correspondence.package_document_type.name == "10182"
        correspondence.nod = true
      end
      correspondence.save(validate: false)
    end
  end
end
