namespace :correspondence do 
	desc "Update nod column of correspondences table according to name of package_document_types table"

	task update_nod: [:environment] do
		correspondences = Correspondence.includes(:package_document_type)
		correspondences.each do |correspondence|
			if correspondence.package_document_type && correspondence.package_document_type.name == "10182"
				correspondence.update!(nod: true)
			else
				correspondence.update!(nod: false)
			end
		end
	end
end