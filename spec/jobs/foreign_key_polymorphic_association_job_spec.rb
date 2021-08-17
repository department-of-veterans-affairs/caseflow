# frozen_string_literal: true

require "query_subscriber"
require "anbt-sql-formatter/formatter"

describe ForeignKeyPolymorphicAssociationJob, :postgres do
  subject { described_class.perform_now }

  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { true }
  end

  let(:appeal) { create(:appeal) }
  let!(:sil) { SpecialIssueList.create(appeal: appeal) }
  let(:legacy_appeal) { create(:legacy_appeal) }
  let!(:leg_sil) { SpecialIssueList.create(appeal: legacy_appeal) }

  context "_id is nil regardless of existence of associated record" do
    before do
      sil.update_attribute(:appeal_id, nil)
      sil.update_attribute(:appeal_type, nil)
      appeal.destroy! if [true, false].sample
    end
    it "does not send alert" do
      expect(Appeal.count).to eq(0).or eq(1)
      subject
      expect(slack_service).not_to have_received(:send_notification)
    end
  end

  context "_id is non-nil and associated record exists" do
    it "does not send alert" do
      subject
      expect(slack_service).not_to have_received(:send_notification)
    end
  end

  context "_id is nil but _type is non-nil" do
    before do
      sil.update_attribute(:appeal_id, nil)
      appeal.destroy! if [true, false].sample
    end
    it "sends alert" do
      expect(Appeal.count).to eq(0).or eq(1)
      expect(sil.appeal_type).not_to eq nil

      subject

      message = /Found [[:digit:]]+ unusual records for SpecialIssueList:.*\[#{sil.id}, "Appeal", nil\]/m
      expect(slack_service).to have_received(:send_notification).with(message, any_args).once
    end
  end

  context "_id is non-nil but _type is nil" do
    let(:hearing) { create(:hearing) }
    let!(:her) { HearingEmailRecipient.create(hearing: hearing) }
    before do
      her.update_attribute(:hearing_type, nil)
    end
    it "sends alert" do
      expect(Hearing.count).to eq(1)
      expect(her.hearing_type).to eq nil

      subject

      message = /Found [[:digit:]]+ unusual records for HearingEmailRecipient:.*\[#{her.id}, nil, #{hearing.id}\]/m
      expect(slack_service).to have_received(:send_notification).with(message, any_args).once
    end
  end

  # This is the main objective of the job
  context "_id is non-nil but the associated record doesn't exist" do
    before do
      appeal.destroy!
    end
    it "sends alert" do
      expect(Appeal.count).to eq 0

      subject

      message = /Found [[:digit:]]+ orphaned records for SpecialIssueList:.*\[#{sil.id}, "Appeal", #{sil.appeal_id}\]/m
      expect(slack_service).to have_received(:send_notification).with(message, any_args).once
    end

    context "check for N+1 query problem" do
      let(:query_subscriber) { QuerySubscriber.new }
      let(:formatter) { AnbtSql::Formatter.new(AnbtSql::Rule.new) }
      before { 2.times { SpecialIssueList.create(appeal: create(:appeal)) } }

      it "sends alert" do
        expect(Appeal.count).to eq 2

        query_subscriber.track do
          subject
        end

        # There should be no more than 2 queries per CLASSES_WITH_POLYMORPH_ASSOC configuration
        application_queries = query_subscriber.select_queries.reject { |query| query.include?("pg_attribute") }
        polymorphic_assoc_configs = ForeignKeyPolymorphicAssociationJob::CLASSES_WITH_POLYMORPH_ASSOC.values.flatten
        expect(application_queries.size).to be < 2 * polymorphic_assoc_configs.size
        # print SQL queries so they can be tested manually in dbconsole or Metabase
        application_queries.each { |query| puts formatter.format(query.dup) }

        # 1 SELECT for orphan_records + 1 SELECT for unusual_records
        expect(query_subscriber.select_queries(/"special_issue_lists"/).size).to eq 2

        heading = "Found [[:digit:]]+ orphaned records for SpecialIssueList"
        message = /#{heading}:.*\[#{sil.id}, "Appeal", #{sil.appeal_id}\]/m
        expect(slack_service).to have_received(:send_notification).with(message, any_args).once
      end
    end

    context "records for multiple classes where _id exists but the associated record doesn't" do
      let(:document_params) do
        {
          appeal_id: appeal.id,
          appeal_type: appeal.class.name,
          document_type: "BVA Decision",
          file: ""
        }
      end
      let!(:vbms_doc) { VbmsUploadedDocument.create(document_params) }

      before do
        appeal.destroy!
      end
      it "sends multiple alerts" do
        expect(Appeal.count).to eq 0

        subject

        message = /Found [[:digit:]]+ orphaned record/
        expect(slack_service).to have_received(:send_notification).with(message, any_args).twice
      end
    end
  end

  context "when checking Claimant.participant_id foreign key" do
    let(:claimant) { appeal.claimant }
    before { 2.times { create(:appeal) } }
    context "associated Person exists" do
      it "does not send alert" do
        expect(claimant.reload_person).not_to eq nil
        expect(Person.find_by_participant_id(claimant.participant_id)).not_to eq nil
        subject
        expect(slack_service).not_to have_received(:send_notification)
      end
    end
    context "associated Person does not exist" do
      before do
        claimant.person.destroy!
      end
      it "sends alert" do
        expect(claimant.reload_person).to eq nil
        expect(Person.find_by_participant_id(claimant.participant_id)).to eq nil
        expect(Claimant.count).to eq 3
        expect(Person.count).to eq 2
        subject

        heading = "Found [[:digit:]]+ orphaned records for Claimant"
        message = /#{heading}:.*\[#{claimant.id}, nil, "#{claimant.participant_id}"\]/m
        expect(slack_service).to have_received(:send_notification).with(message, any_args).once
      end
    end
  end
end
