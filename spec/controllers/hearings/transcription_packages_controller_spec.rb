# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::TranscriptionPackagesController, type: :controller do
  describe "GET transcription_package_tasks" do
    let!(:user) { User.authenticate!(roles: ["Transcriptions"]) }
    # before { TranscriptionTeam.singleton.add_user(user) }

    # let(:c_1) { create(:transcription_contractor) }
    # let(:c_2) { create(:transcription_contractor) }
    # let(:c_3) { create(:transcription_contractor) }

    # let(:transcription_package_1) { create(:transcription_package, task_number: "BVA2024001", contractor: c_1) }
    # let(:transcription_package_2) { create(:transcription_package, task_number: "BVA2024002", contractor: c_2) }
    # let(:transcription_package_3) { create(:transcription_package, task_number: "BVA2024003", contractor: c_3) }
    # let(:transcription_package_4) { create(:transcription_package, task_number: "BVA2024004", contractor: c_1) }

    # let(:package_response_1) do
    #   {
    #     id: transcription_package_1.id,
    #     workOrder: transcription_package_1.task_number,
    #     items: 25,
    #     dateSent: transcription_package_1.created_at.to_formatted_s(:short_date),
    #     expectedReturnDate: transcription_package_1.expected_return_date.to_formatted_s(:short_date),
    #     contractor: transcription_package_1.contractor.name,
    #     status: transcription_package_1.status
    #   }
    # end

    # let(:package_response_2) do
    #   {
    #     id: transcription_package_2.id,
    #     workOrder: transcription_package_2.task_number,
    #     items: 25,
    #     dateSent: transcription_package_2.created_at.to_formatted_s(:short_date),
    #     expectedReturnDate: transcription_package_2.expected_return_date.to_formatted_s(:short_date),
    #     contractor: transcription_package_2.contractor.name,
    #     status: transcription_package_2.status
    #   }
    # end

    # let(:package_response_3) do
    #   {
    #     id: transcription_package_3.id,
    #     workOrder: transcription_package_3.task_number,
    #     items: 25,
    #     dateSent: transcription_package_3.created_at.to_formatted_s(:short_date),
    #     expectedReturnDate: transcription_package_3.expected_return_date.to_formatted_s(:short_date),
    #     contractor: transcription_package_3.contractor.name,
    #     status: transcription_package_3.status
    #   }
    # end

    # let(:package_response_4) do
    #   {
    #     id: transcription_package_4.id,
    #     workOrder: transcription_package_4.task_number,
    #     items: 25,
    #     dateSent: transcription_package_4.created_at.to_formatted_s(:short_date),
    #     expectedReturnDate: transcription_package_4.expected_return_date.to_formatted_s(:short_date),
    #     contractor: transcription_package_4.contractor.name,
    #     status: transcription_package_4.status
    #   }
    # end

    it "returns a pagenated result" do
      get :transcription_package_tasks, params: { page_size: 2 }

      # expected_response = {
      #   task_page_count: 2,
      #   tasks: {
      #     data: [package_response_4, package_response_3]
      #   },
      #   tasks_per_page: 2,
      #   total_task_count: 4
      # }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end
  end
end
