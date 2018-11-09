require "rails_helper"

describe RequestIssuesUpdate do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))

    review.create_issues!(existing_request_issues)
  end

  # TODO: make it simpler to set up a completed claim review, with end product data
  # and contention data stubbed out properly
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }

  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let(:rating_end_product_establishment) do
    create(
      :end_product_establishment,
      veteran_file_number: veteran.file_number,
      source: review,
      code: "030HLRR"
    )
  end

  let(:request_issue_contentions) do
    [
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for PTSD was granted at 10 percent"
      ),
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for left knee immobility was denied"
      )
    ]
  end

  let!(:existing_request_issues) do
    [
      RequestIssue.new(
        review_request: review,
        rating_issue_profile_date: Time.zone.local(2017, 4, 5),
        rating_issue_reference_id: "issue1",
        contention_reference_id: request_issue_contentions[0].id,
        description: request_issue_contentions[0].text,
        rating_issue_associated_at: 5.days.ago
      ),
      RequestIssue.new(
        review_request: review,
        rating_issue_profile_date: Time.zone.local(2017, 4, 6),
        rating_issue_reference_id: "issue2",
        contention_reference_id: request_issue_contentions[1].id,
        description: request_issue_contentions[1].text,
        rating_issue_associated_at: 5.days.ago
      )
    ]
  end

  let(:request_issues_update) do
    RequestIssuesUpdate.new(
      user: user,
      review: review,
      request_issues_data: request_issues_data
    )
  end

  let(:user) { create(:user) }

  let(:request_issues_data) { [] }

  let(:existing_request_issues_data) do
    existing_request_issues.map do |issue|
      {
        reference_id: issue.rating_issue_reference_id,
        profile_date: issue.rating_issue_profile_date,
        decision_text: issue.description
      }
    end
  end

  let(:after_ama_start_date) { Time.zone.local(2017, 11, 7) }

  let(:request_issues_data_with_new_issue) do
    existing_request_issues_data + [{
      reference_id: "issue3",
      profile_date: after_ama_start_date,
      decision_text: "Service connection for cancer was denied"
    }]
  end

  context "async logic scopes" do
    let!(:riu_requiring_processing) do
      create(:request_issues_update).tap(&:submit_for_processing!)
    end

    let!(:riu_processed) do
      create(:request_issues_update).tap(&:processed!)
    end

    let!(:riu_recently_attempted) do
      create(
        :request_issues_update,
        attempted_at: (RequestIssuesUpdate::REQUIRES_PROCESSING_RETRY_WINDOW_HOURS - 1).hours.ago
      )
    end

    let!(:riu_attempts_ended) do
      create(
        :request_issues_update,
        submitted_at: (RequestIssuesUpdate::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
        attempted_at: (RequestIssuesUpdate::REQUIRES_PROCESSING_WINDOW_DAYS + 1).days.ago
      )
    end

    context ".unexpired" do
      it "matches inside the processing window" do
        expect(described_class.unexpired).to eq([riu_requiring_processing])
      end
    end

    context ".processable" do
      it "matches eligible for processing" do
        expect(described_class.processable).to match_array(
          [riu_requiring_processing, riu_attempts_ended]
        )
      end
    end

    context ".attemptable" do
      it "matches could be attempted" do
        expect(described_class.attemptable).not_to include(riu_recently_attempted)
      end
    end

    context ".requires_processing" do
      it "matches must still be processed" do
        expect(described_class.requires_processing).to eq([riu_requiring_processing])
      end
    end

    context ".expired_without_processing" do
      it "matches unfinished but outside the retry window" do
        expect(described_class.expired_without_processing).to eq([riu_attempts_ended])
      end
    end
  end

  context "#created_issues" do
    subject { request_issues_update.created_issues }
    before { request_issues_update.perform! }

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { request_issues_data_with_new_issue }
      let(:new_request_issue) { RequestIssue.find_by(rating_issue_reference_id: "issue3") }

      it { is_expected.to contain_exactly(new_request_issue) }
    end

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it { is_expected.to eq([]) }
    end
  end

  context "#removed_issues" do
    subject { request_issues_update.removed_issues }
    before { request_issues_update.perform! }

    context "when new issues were removed as part of the update" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it { is_expected.to contain_exactly(existing_request_issues.last) }
    end

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { request_issues_data_with_new_issue }

      it { is_expected.to eq([]) }
    end
  end

  context "#perform!" do
    let(:vbms_error) { VBMS::HTTPError.new("500", "More EPs more problems") }

    subject { request_issues_update.perform! }

    context "when request issues are empty" do
      it "fails and adds to errors" do
        expect(subject).to be_falsey

        expect(request_issues_update.error_code).to eq(:request_issues_data_empty)
      end
    end

    context "when issues are exactly the same as existing issues" do
      let(:request_issues_data) { existing_request_issues_data }

      it "fails and adds to errors" do
        expect(subject).to be_falsey

        expect(request_issues_update.error_code).to eq(:no_changes)
      end
    end

    context "when issues contain new issues not in existing issues" do
      let(:request_issues_data) { request_issues_data_with_new_issue }

      it "saves update, adds issues, and calls create contentions" do
        allow_create_contentions
        allow_associate_rating_request_issues

        expect(subject).to be_truthy
        request_issues_update.reload

        expect(request_issues_update.before_request_issue_ids).to contain_exactly(
          *existing_request_issues.map(&:id)
        )

        expect(request_issues_update.after_request_issue_ids).to contain_exactly(
          *(existing_request_issues.map(&:id) + [review.request_issues.last.id])
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          hash_including(
            veteran_file_number: review.veteran_file_number,
            contention_descriptions: ["Service connection for cancer was denied"],
            special_issues: []
          )
        )

        expect(review.request_issues.count).to eq(3)

        new_map = rating_end_product_establishment.send(
          :rating_issue_contention_map,
          review.request_issues.reload
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
          claim_id: rating_end_product_establishment.reference_id,
          rating_issue_contention_map: new_map
        )

        review.request_issues.map(&:rating_issue_associated_at).each do |value|
          expect(value).to eq(Time.zone.now)
        end

        created_issue = review.request_issues.find_by(rating_issue_reference_id: "issue3")
        expect(created_issue).to have_attributes(
          rating_issue_profile_date: after_ama_start_date,
          description: "Service connection for cancer was denied"
        )
        expect(created_issue.contention_reference_id).to_not be_nil
      end

      context "with nonrating request issue" do
        let(:request_issues_data) do
          existing_request_issues_data + [{
            reference_id: "issue3",
            decision_text: "Nonrating issue",
            issue_category: "Apportionment",
            decision_date: 1.month.ago
          }]
        end

        let(:review) do
          create(:higher_level_review,
                 veteran_file_number: veteran.file_number,
                 informal_conference: true)
        end

        it "adds new end product for a new rating type" do
          expect(EndProductEstablishment.find_by(code: "030HLRNR", source: review)).to eq(nil)

          subject
          ep = EndProductEstablishment.find_by(code: "030HLRNR", source: review)
          expect(ep).to_not be_nil
          # informal conference should also have been created
          expect(ep.development_item_reference_id).to_not be_nil
        end
      end
    end

    context "when issues contain a subset of existing issues" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      let(:nonrating_end_product_establishment) do
        create(
          :end_product_establishment,
          veteran_file_number: veteran.file_number,
          source: review,
          code: "030HLRNR"
        )
      end

      let(:nonrating_request_issue_contention) do
        Generators::Contention.build(
          claim_id: nonrating_end_product_establishment.reference_id,
          text: "Nonrating issue"
        )
      end

      it "saves update, removes issues, and calls remove contentions" do
        allow_remove_contention
        allow_associate_rating_request_issues

        expect(subject).to be_truthy

        request_issues_update.reload
        expect(request_issues_update.before_request_issue_ids).to contain_exactly(
          *existing_request_issues.map(&:id)
        )

        expect(request_issues_update.after_request_issue_ids).to contain_exactly(
          existing_request_issues.first.id
        )

        removed_issue = existing_request_issues.last.reload
        expect(removed_issue).to have_attributes(
          review_request: nil
        )
        expect(removed_issue.removed_at).to_not be_nil

        expect(Fakes::VBMSService).to have_received(:remove_contention!).with(request_issue_contentions.last)

        new_map = rating_end_product_establishment.send(
          :rating_issue_contention_map,
          review.request_issues.reload
        )

        expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
          claim_id: rating_end_product_establishment.reference_id,
          rating_issue_contention_map: new_map
        )

        expect(review.request_issues.first.rating_issue_associated_at).to eq(Time.zone.now)

        # ep should not be canceled because 1 rating request issue still exists
        rating_end_product_establishment.reload
        expect(rating_end_product_establishment.synced_status).to eq(nil)
      end

      it "cancels end products with no request issues" do
        create(
          :request_issue,
          review_request: review,
          end_product_establishment: nonrating_end_product_establishment,
          contention_reference_id: nonrating_request_issue_contention.id,
          description: nonrating_request_issue_contention.text,
          issue_category: "Apportionment"
        )

        expect_any_instance_of(Fakes::BGSService).to receive(:cancel_end_product).with(
          veteran.file_number,
          "030HLRNR",
          "030"
        )

        allow_remove_contention
        allow_associate_rating_request_issues

        expect(subject).to be_truthy

        # expect end product to be canceled
        found_nonrating_ep = EndProductEstablishment.find_by(
          id: nonrating_end_product_establishment.id,
          synced_status: "CAN"
        )

        expect(found_nonrating_ep).to_not be_nil
      end
    end

    context "when create_contentions raises VBMS service error" do
      let(:request_issues_data) { request_issues_data_with_new_issue }

      it "saves error message and logs error" do
        capture_raven_log
        raise_error_on_create_contentions

        subject

        expect(request_issues_update.error).to eq(vbms_error.to_s)
        expect(@raven_called).to eq(true)
      end
    end

    context "when remove_contention raises VBMS service error" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it "saves error message and logs error" do
        capture_raven_log
        raise_error_on_remove_contention

        subject

        expect(request_issues_update.error).to eq(vbms_error.to_s)
        expect(@raven_called).to eq(true)
      end
    end

    def capture_raven_log
      allow(Raven).to receive(:capture_exception) { @raven_called = true }
    end

    def raise_error_on_create_contentions
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_raise(vbms_error)
    end

    def allow_create_contentions
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    end

    def allow_associate_rating_request_issues
      allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
    end

    def raise_error_on_remove_contention
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_raise(vbms_error)
    end

    def allow_remove_contention
      allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original
    end
  end
end
