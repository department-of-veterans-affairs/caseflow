# frozen_string_literal: true

RSpec.configure do |rspec|
  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  # source: https://rspec.info/features/3-12/rspec-core/example-groups/shared-context/
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "veterans", shared_context: :metadata do
  # ***********************************************************************************
  #                           Run Remediation Test Context
  # ***********************************************************************************

  # -----------------------------------------------------------------------------------
  # --- Veteran pair
  # -----------------------------------------------------------------------------------
  let(:ssn2) { "37945407" }
  let(:participant_id_1) { "556789" }
  let(:participant_id_2) { "987655" }
  let(:dup_pair_vet_number1) { "112233445" }
  let(:dup_pair_vet_number2) { "556677889" }

  let!(:dup_veteran1) do
    create(:veteran, file_number: dup_pair_vet_number1, ssn: ssn2, participant_id: participant_id_1)
  end

  let!(:dup_veteran2) do
    create(:veteran, file_number: dup_pair_vet_number2, ssn: ssn2, participant_id: participant_id_2)
  end

  # --- Instanciate duplicate veteran fixer
  let(:duplicate_vet_fixer) { DuplicateVeteranFixer.new(dup_pair_vet_number1) }

  # --- Set variables
  let!(:bgs) { dup_veteran2.file_number }
  let!(:v1_file_number) { dup_veteran1.file_number }
  let!(:v2_file_number) { dup_veteran2.file_number }
  let!(:v1_vbms_id) { "#{dup_veteran1.file_number}S" }
  let!(:v2_vbms_id) { "#{dup_veteran2.file_number}S" }

  # -----------------------------------------------------------------------------------
  # --- Relations
  # -----------------------------------------------------------------------------------

  # --- dup_veteran1 Relations
  let!(:v1_appeals) { create_list(:appeal, 2, veteran_file_number: v1_file_number) }

  before :each do
    v1_legacy_appeal.case_record.folder.update!(titrnum: v1_vbms_id)
    v1_legacy_appeal.case_record.correspondent.update!(slogid: v1_vbms_id)
  end

  let!(:v1_legacy_appeal) do
    create(:legacy_appeal, vbms_id: v1_vbms_id,
                           vacols_case: create(:case, bfcorlid: v1_vbms_id))
  end

  let!(:v1_bgs_poas) { create_list(:bgs_power_of_attorney, 1, file_number: v1_file_number) }
  let!(:v1_documents) { create_list(:document, 3, file_number: v1_file_number) }
  let!(:v1_end_product_establishments) do
    create_list(:end_product_establishment, 1, veteran_file_number: v1_file_number)
  end
  let!(:v1_supplemental_claims) do
    create(:supplemental_claim, veteran_file_number: v1_file_number,
                                establishment_error: "VBMS::DuplicateVeteranRecords")
  end

  let(:v1_vfn_relations) { [v1_appeals, v1_end_product_establishments, v1_supplemental_claims] }
  let(:v1_fn_relations) { [v1_documents, v1_bgs_poas].flatten }

  # --- dup_veteran2 Relations
  let!(:v2_appeals) { create_list(:appeal, 1, veteran_file_number: v2_file_number) }
  let!(:v2_documents) { create_list(:document, 1, file_number: v2_file_number) }
  let!(:v2_f8s) { create(:form8, file_number: v2_vbms_id) }
  let!(:v2_hlrs) { create(:higher_level_review, veteran_file_number: v2_file_number) }
  let!(:v2_supplemental_claims) { create(:supplemental_claim, veteran_file_number: v2_file_number) }

  let(:v2_vfn_relations) { [v2_appeals, v2_supplemental_claims] }
end

# -----------------------------------------------------------------------------------
# --- Helpers
# -----------------------------------------------------------------------------------

def find_list_based_on_identifier(relation, identifier, id)
  subject.send(:find_list_based_on_identifier, relation, identifier, id)
end

def get_relation_list(relation, identifier)
  subject.send(:get_relation_list, relation, identifier)
end

RSpec.configure do |rspec|
  rspec.include_context "veterans", include_shared: true
end
