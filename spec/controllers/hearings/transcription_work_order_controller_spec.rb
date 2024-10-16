# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::TranscriptionWorkOrderController, type: :controller do
  let(:task_number) { "TASK123" }

  before do
    User.authenticate!(roles: ["System Admin"])
  end

  describe "GET #display_wo_summary" do
    context "when work order summary is found" do
      let(:wo_summary) do
        {
          "return_date" => "2024-01-01",
          "work_order" => task_number,
          "contractor_name" => "Contractor X",
          "wo_file_info" => [
            {
              "docket_number" => "D123",
              "case_type" => "Type A",
              "hearing_date" => "2024-01-01",
              "first_name" => "John",
              "last_name" => "Doe",
              "judge_name" => "Judge Judy",
              "regional_office" => "RO City",
              "types" => "Type 1, Type 2"
            }
          ]
        }
      end

      before do
        allow(::TranscriptionWorkOrder).to receive(:display_wo_summary).and_return(wo_summary)
        request.accept = "application/json"
        get :display_wo_summary, params: { task_number: task_number }
      end

      it "returns a success response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the work order summary in JSON" do
        expect(JSON.parse(response.body)).to eq({ "data" => wo_summary })
      end
    end
  end

  describe "GET #display_wo_contents" do
    context "when work order contents are found" do
      let(:wo_contents) do
        [
          {
            "docket_number" => "D123",
            "case_details" => "Details of case"
          }
        ]
      end

      before do
        allow(::TranscriptionWorkOrder).to receive(:display_wo_contents).with(task_number).and_return(wo_contents)
        get :display_wo_contents, params: { task_number: task_number }
      end

      it "returns a success response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the work order contents in JSON" do
        expect(JSON.parse(response.body)).to eq({ "data" => wo_contents })
      end
    end

    context "when work order contents are not found" do
      before do
        allow(::TranscriptionWorkOrder).to receive(:display_wo_contents).with(task_number).and_return(nil)
        get :display_wo_contents, params: { task_number: task_number }
      end

      it "returns a not found response" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Transcription content not found." })
      end
    end
  end

  describe "POST #unassign_wo" do
    context "when unassigning work order is successful" do
      let(:banner_messages) do
        {
          "hearing_message" => "Some hearing message",
          "work_order_message" => "Work order message for Contractor X"
        }
      end

      before do
        allow(::TranscriptionWorkOrder).to receive(:unassign_wo).with(task_number).and_return(banner_messages)
        post :unassign_wo, params: { task_number: task_number }
      end

      it "returns a success response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the banner messages in JSON" do
        expect(JSON.parse(response.body)).to eq({ "data" => banner_messages })
      end
    end

    context "when unassigning work order fails" do
      before do
        allow(::TranscriptionWorkOrder)
          .to receive(:unassign_wo)
          .with(task_number)
          .and_raise(StandardError.new("An error occurred"))

        post :unassign_wo, params: { task_number: task_number }
      end

      it "returns an internal server error response" do
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns an error message in JSON" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Something went wrong." })
      end
    end
  end

  describe "POST #unassigning_work_order" do
    context "when unassigning work order is successful" do
      before do
        allow(Transcription)
          .to receive(:unassign_by_task_number)
          .with(task_number).and_return(true)

        allow(TranscriptionPackage)
          .to receive(:cancel_by_task_number)
          .with(task_number).and_return(true)

        allow(Hearings::TranscriptionFile)
          .to receive(:reset_files)
          .with(task_number).and_return(true)

        post :unassigning_work_order, params: { task_number: task_number }
      end

      it "returns a success response" do
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
