# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::TranscriptionPackagesController, type: :controller do
  describe "GET transcription_package_tasks" do
    let!(:user) { User.authenticate!(roles: ["Transcriptions"]) }
    before { TranscriptionTeam.singleton.add_user(user) }

    let!(:h_1) { create(:hearing) }

    let!(:c_1) { create(:transcription_contractor, name: "Contractor One") }
    let!(:c_2) { create(:transcription_contractor, name: "Contractor Two") }
    let!(:c_3) { create(:transcription_contractor, name: "Contractor Three") }

    let!(:t_1) { create(:transcription,  task_number: "BVA2024001") }
    let!(:t_2) { create(:transcription,  task_number: "BVA2024002") }
    let!(:t_3) { create(:transcription,  task_number: "BVA2024003") }
    let!(:t_4) { create(:transcription,  task_number: "BVA2024004") }

    let!(:tf_1) { create(:transcription_file, transcription: t_1) }
    let!(:tf_2) { create(:transcription_file, transcription: t_2) }
    let!(:tf_3) { create(:transcription_file, transcription: t_3) }
    let!(:tf_4) { create(:transcription_file, transcription: t_4) }

    let!(:transcription_package_1) do
      create(
        :transcription_package,
        task_number: "BVA2024001",
        contractor: c_1,
        created_at: "2024-09-01 00:00:00",
        expected_return_date: "2024-09-15",
        status: "Overdue",
        hearings: [h_1]
      )
    end

    let!(:transcription_package_2) do
      create(
        :transcription_package,
        task_number: "BVA2024002",
        contractor: c_2,
        created_at: "2024-09-02 00:00:00",
        expected_return_date: "2024-09-16",
        status: "Successful Upload (BOX)",
        hearings: [h_1]
      )
    end

    let!(:transcription_package_3) do
      create(
        :transcription_package,
        task_number: "BVA2024003",
        contractor: c_3,
        created_at: "2024-09-03 00:00:00",
        expected_return_date: "2024-09-17",
        status: "Successful Upload (BOX)",
        hearings: [h_1]
      )
    end

    let!(:transcription_package_4) do
      create(
        :transcription_package,
        task_number: "BVA2024004",
        contractor: c_1,
        created_at: "2024-09-04 00:00:00",
        expected_return_date: "2024-09-18",
        status: "Overdue",
        hearings: [h_1]
      )
    end

    let!(:package_response_1) do
      {
        id: transcription_package_1.id,
        workOrder: transcription_package_1.task_number,
        items: 1,
        dateSent: transcription_package_1.created_at.to_formatted_s(:short_date),
        expectedReturnDate: transcription_package_1.expected_return_date.to_formatted_s(:short_date),
        contractor: transcription_package_1.contractor.name,
        status: transcription_package_1.status
      }
    end

    let!(:package_response_2) do
      {
        id: transcription_package_2.id,
        workOrder: transcription_package_2.task_number,
        items: 1,
        dateSent: transcription_package_2.created_at.to_formatted_s(:short_date),
        expectedReturnDate: transcription_package_2.expected_return_date.to_formatted_s(:short_date),
        contractor: transcription_package_2.contractor.name,
        status: "Successful Upload (BOX)"
      }
    end

    let!(:package_response_3) do
      {
        id: transcription_package_3.id,
        workOrder: transcription_package_3.task_number,
        items: 1,
        dateSent: transcription_package_3.created_at.to_formatted_s(:short_date),
        expectedReturnDate: transcription_package_3.expected_return_date.to_formatted_s(:short_date),
        contractor: transcription_package_3.contractor.name,
        status: "Successful Upload (BOX)"
      }
    end

    let!(:package_response_4) do
      {
        id: transcription_package_4.id,
        workOrder: transcription_package_4.task_number,
        items: 1,
        dateSent: transcription_package_4.created_at.to_formatted_s(:short_date),
        expectedReturnDate: transcription_package_4.expected_return_date.to_formatted_s(:short_date),
        contractor: transcription_package_4.contractor.name,
        status: transcription_package_4.status
      }
    end

    it "returns a paginated result" do
      get :transcription_package_tasks, params: { page_size: 2 }

      expected_response = {
        task_page_count: 2,
        tasks: {
          data: [package_response_4, package_response_3]
        },
        tasks_per_page: 2,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "returns second page of paginated results" do
      get :transcription_package_tasks, params: { page: 2, page_size: 2 }

      expected_response = {
        task_page_count: 2,
        tasks: {
          data: [package_response_2, package_response_1]
        },
        tasks_per_page: 2,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by sent dates" do
      filter = Rack::Utils.build_query({ col: "dateSentColumn", val: "between,2024-09-02,2024-09-03" })

      get :transcription_package_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_3, package_response_2]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by expected return dates" do
      filter = Rack::Utils.build_query({ col: "expectedReturnDateColumn", val: "between,2024-09-16,2024-09-17" })

      get :transcription_package_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_3, package_response_2]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by contractor name" do
      filter = Rack::Utils.build_query({ col: "contractorColumn", val: "Contractor One" })

      get :transcription_package_tasks, params: { filter: [filter] }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_4, package_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "filters by search" do
      get :transcription_package_tasks, params: { search: "BVA2024003" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_3]
        },
        tasks_per_page: 15,
        total_task_count: 1
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "orders by date sent" do
      get :transcription_package_tasks, params: { sort_by: "dateSentColumn", order: "desc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_4, package_response_3, package_response_2, package_response_1]
        },
        tasks_per_page: 15,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "orders by expected return date" do
      get :transcription_package_tasks, params: { sort_by: "expectedReturnDateColumn", order: "asc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_1, package_response_2, package_response_3, package_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "orders by contractor name" do
      get :transcription_package_tasks, params: { sort_by: "contractorColumn", order: "desc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_2, package_response_3, package_response_1, package_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 4
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end

    it "combines ordering and filtering" do
      filter = Rack::Utils.build_query({ col: "contractorColumn", val: "Contractor One" })

      get :transcription_package_tasks, params: { filter: [filter], sort_by: "dateSentColumn", order: "asc" }

      expected_response = {
        task_page_count: 1,
        tasks: {
          data: [package_response_1, package_response_4]
        },
        tasks_per_page: 15,
        total_task_count: 2
      }.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_response)
    end
  end
end
