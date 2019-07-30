# frozen_string_literal: true

require "rails_helper"

describe Api::V3::RequestIssuePreintake do
  context "contests on_file_decision" do


    it "should work with valid hash" do
      r = Api::V3::RequestIssuePreintake.new(
        hash: {
          "type" => "request_issue",
          "attributes" => {
            "contests" => "on_file_decision",
            "decision_id" => "232",
            "notes" => "Here are some notes"
          }
        }
      )
      expect(r.notes).to be "Here are some notes"
      expect(r.decision_id).to be 232
    end


    
    it "extra key should fail" do
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_decision",
              "decision_id" => "232",
              "notes" => "Here are some notes"
            },
            "other" => 555
          }
        )
      end.to raise_error ArgumentError
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_decision",
              "decision_id" => "232",
              "notes" => "Here are some notes",
              "other" => 555
            }
          }
        )
      end.to raise_error ArgumentError
    end



    it "missing key should fail" do
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "attributes" => {
              "contests" => "on_file_decision",
              "decision_id" => "232",
              "notes" => "Here are some notes",
            }
          }
        )
      end.to raise_error ArgumentError
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
          }
        )
      end.to raise_error ArgumentError
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
            "attributes" => {
              "decision_id" => "232",
              "notes" => "Here are some notes",
            }
          }
        )
      end.to raise_error ArgumentError
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_decision",
              "notes" => "Here are some notes",
            }
          }
        )
      end.to raise_error ArgumentError
      expect do
        Api::V3::RequestIssuePreintake.new(
          hash: {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_decision",
              "decision_id" => "232",
            }
          }
        )
      end.to raise_error ArgumentError
    end



    it "invalid type should fail" do
      ["request_issueS", "cat", "", nil, true, false, [], ["a"], {}, {a: 1}, 44, "33"].each do |type|
        expect do
          Api::V3::RequestIssuePreintake.new(
            hash: {
              "type" => type,
              "attributes" => {
                "contests" => "on_file_decision",
                "decision_id" => "232",
                "notes" => "Here are some notes",
              }
            }
          )
        end.to raise_error ArgumentError
      end
    end
  end
end
