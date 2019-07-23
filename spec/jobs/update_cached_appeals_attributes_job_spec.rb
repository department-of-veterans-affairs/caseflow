# frozen_string_literal: true

require "rails_helper"

describe UpdateCachedAppealsAttributesJob do
  #
  # let!(:vacols_case1) { create(:case) }
  # let!(:vacols_case2) { create(:case) }

  # let!(:legacy_appeal1) { FactoryBot.create(:legacy_appeal, vacols_case: vacols_case1) }
  # let!(:legacy_appeal2) { FactoryBot.create(:legacy_appeal, vacols_case: vacols_case2) }

  let(:appeal1) { FactoryBot.create(:appeal) }
  let(:appeal2) { FactoryBot.create(:appeal) }
  let(:appeal3) { FactoryBot.create(:appeal) }

  # let!(:ama_appeals) { [appeal1, appeal2, appeal3] }


  context "when the job runs successfully" do
    # let!(:legacy_appeals) { [legacy_appeal1, legacy_appeal2] }

      # legacy_appeals.each do |appeal|
      #   FactoryBot.create(:bva_dispatch_task, :in_progress, appeal: appeal, appeal_type: LegacyAppeal.name)
      #   FactoryBot.create(:ama_judge_task, :completed, appeal: appeal, appeal_type: LegacyAppeal.name)
      #   FactoryBot.create(:ama_attorney_task, :in_progress, appeal: appeal, appeal_type: LegacyAppeal.name)
      # end

      # ama_appeals.each do |appeal|
      #   FactoryBot.create(:bva_dispatch_task, :in_progress, appeal: appeal, appeal_type: Appeal.name)
      #   FactoryBot.create(:ama_judge_task, :completed, appeal: appeal, appeal_type: Appeal.name)
      #   FactoryBot.create(:ama_attorney_task, :in_progress, appeal: appeal, appeal_type: Appeal.name)
      # end
      #
      # UpdateCachedAppealsAttributesJob.perform_now

      let!(:ama_appeals) { [appeal1, appeal2, appeal3] }
      


    it "creates the correct number of cached appeals" do

      ama_appeals.each do |appeal|
        FactoryBot.create(:bva_dispatch_task, :in_progress, appeal: appeal, appeal_type: Appeal.name)
        FactoryBot.create(:ama_judge_task, :completed, appeal: appeal, appeal_type: Appeal.name)
        FactoryBot.create(:ama_attorney_task, :in_progress, appeal: appeal, appeal_type: Appeal.name)
      end

      UpdateCachedAppealsAttributesJob.perform_now

      expect(Task.all.count).to eq(12)
      expect(Task.open.count).to eq(9)

      expect(CachedAppeal.all.count).to eq(3)

    end

  end

end



# describe UpdateCachedAppealsAttributesJob do
#   let(:vacols_folder1) {
#     VACOLS::Folder.create(ticknum: "1")
#   }
#   let(:vacols_folder2) {
#     VACOLS::Folder.create(ticknum: "2")
#   }
#
#   let(:legacy_appeal1) { LegacyAppeal.create(vacols_id: "1") }
#   let(:appeal2) { LegacyAppeal.create(vacols_id: "2") }
#
#   context "When there are open legacy and AMA appeals, the cache" do
#
#     it "creates cached appeals for all appeals associated with open tasks" do
#     end
#
#     if "associates the correct docket_number with the correct vacols_id" do
#     end
#
#     it "creates the proper docket numbers for AMA appeals" do
#     end
#
#     it "creates the correct number of cached appeals" do
#     end
#
#     it "does not create more than 1 cached appeal for each appeal" do
#     end
#
#     it "caches the docket_types correctly" do
#     end
#
#     it "fails gracefully" do
#     end
#
#
#   end
#
#
# end
