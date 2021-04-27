# frozen_string_literal: true

describe RequestIssuesUpdate, :all_dbs do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))
  end

  def allow_associate_rating_request_issues
    allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
  end

  def allow_remove_contention
    allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original
  end

  def allow_update_contention
    allow(Fakes::VBMSService).to receive(:update_contention!).and_call_original
  end

  # TODO: make it simpler to set up a completed claim review, with end product data
  # and contention data stubbed out properly
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }

  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let!(:intake_user) { create(:user) }
  let(:edit_user) { create(:user) }

  let(:rating_end_product_establishment) do
    create(
      :end_product_establishment,
      veteran_file_number: veteran.file_number,
      source: review,
      code: "030HLRR",
      user_id: intake_user.id
    )
  end

  let(:request_issue_contentions) do
    [
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for PTSD was granted at 10 percent",
        start_date: Time.zone.now,
        submit_date: 8.days.ago
      ),
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for left knee immobility was denied",
        start_date: Time.zone.now,
        submit_date: 8.days.ago
      )
    ]
  end

  let!(:vacols_id) { "vacols_id" }
  let!(:vacols_sequence_id) { 1 }
  let!(:vacols_issue) { create(:case_issue, issseq: vacols_sequence_id) }
  let!(:vacols_case) { create(:case, bfkey: vacols_id, case_issues: [vacols_issue, create(:case_issue, issseq: 2)]) }
  let(:edited_description) { "I am an edited description" }
  let(:legacy_appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end
  let(:contention_updated_at) { nil }

  let!(:existing_request_issue) do
    RequestIssue.new(
      decision_review: review,
      contested_rating_issue_profile_date: Time.zone.local(2017, 4, 5),
      contested_rating_issue_reference_id: "issue1",
      contention_reference_id: request_issue_contentions[0].id,
      contested_issue_description: request_issue_contentions[0].text,
      rating_issue_associated_at: 5.days.ago,
      contention_updated_at: contention_updated_at
    )
  end

  let!(:existing_legacy_opt_in_request_issue) do
    RequestIssue.new(
      decision_review: review,
      contested_rating_issue_profile_date: Time.zone.local(2017, 4, 6),
      contested_rating_issue_reference_id: "issue2",
      contention_reference_id: request_issue_contentions[1].id,
      contested_issue_description: request_issue_contentions[1].text,
      rating_issue_associated_at: 5.days.ago,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id
    )
  end

  let!(:existing_request_issues) do
    [
      existing_request_issue,
      existing_legacy_opt_in_request_issue
    ]
  end

  let(:request_issues_update) do
    RequestIssuesUpdate.new(
      user: edit_user,
      review: review,
      request_issues_data: request_issues_data
    )
  end

  let(:request_issues_data) { [] }

  let(:after_ama_start_date) { Time.zone.local(2017, 11, 7) }

  before do
    review.create_issues!(existing_request_issues)
  end

  context "after decision review creates existing request issues" do
    let(:request_issues_data_with_new_issue) do
      review.request_issues.map { |issue| { request_issue_id: issue.id } } + [{
        rating_issue_reference_id: "issue3",
        rating_issue_profile_date: after_ama_start_date,
        decision_text: "Service connection for cancer was denied"
      }]
    end

    context "#veteran" do
      it "delegates to review" do
        expect(request_issues_update.veteran).to eq(request_issues_update.review.veteran)
      end
    end

    context "#added_issues" do
      before do
        request_issues_update.perform!
      end

      subject { request_issues_update.added_issues }

      context "when new issues were added as part of the update" do
        let(:request_issues_data) { request_issues_data_with_new_issue }

        let(:new_request_issue) do
          RequestIssue.find_by(
            contested_rating_issue_reference_id: "issue3",
            contested_issue_description: "Service connection for cancer was denied"
          )
        end

        it { is_expected.to contain_exactly(new_request_issue) }
      end

      context "when new issues weren't added as part of the update" do
        let(:request_issues_data) { [{ request_issue_id: existing_legacy_opt_in_request_issue.id }] }

        it { is_expected.to eq([]) }
      end
    end

    context "#removed_issues" do
      before do
        request_issues_update.perform!
      end

      subject { request_issues_update.removed_issues }

      context "when new issues were removed as part of the update" do
        let(:request_issues_data) { [{ request_issue_id: existing_legacy_opt_in_request_issue.id }] }

        it { is_expected.to contain_exactly(existing_request_issue) }
      end

      context "when new issues were added as part of the update" do
        let(:request_issues_data) { request_issues_data_with_new_issue }

        it { is_expected.to eq([]) }
      end
    end

    context "#edited_issues" do
      before do
        request_issues_update.perform!
      end

      subject { request_issues_update.edited_issues }

      context "when issue descriptions were edited as part of the update" do
        let(:request_issues_data) do
          [{ request_issue_id: existing_legacy_opt_in_request_issue.id },
           { request_issue_id: existing_request_issue.id,
             edited_description: edited_description }]
        end

        it { is_expected.to contain_exactly(existing_request_issue) }
      end
    end

    context "#corrected_issues" do
      before do
        request_issues_update.perform!
      end

      subject { request_issues_update.corrected_issues }

      context "when correction issues were part of the update" do
        let(:request_issue_to_correct) { review.request_issues.last }

        let(:request_issues_data) do
          [{ request_issue_id: request_issue_to_correct.id,
             correction_type: "control" }]
        end

        it { is_expected.to contain_exactly(request_issue_to_correct) }
      end
    end

    context "#perform!" do
      let(:vbms_error) { VBMS::HTTPError.new("500", "More EPs more problems") }

      subject { request_issues_update.perform! }

      context "when issues are exactly the same as existing issues" do
        let(:request_issues_data) do
          [{ request_issue_id: existing_legacy_opt_in_request_issue.id },
           { request_issue_id: existing_request_issue.id }]
        end

        it "fails and adds to errors" do
          expect(subject).to be_falsey

          expect(request_issues_update.error_code).to eq(:no_changes)
        end
      end

      context "when an issue's contention text is edited" do
        let(:request_issues_data) do
          [{ request_issue_id: existing_legacy_opt_in_request_issue.id },
           { request_issue_id: existing_request_issue.id,
             edited_description: edited_description }]
        end

        it "updates the request issue's edited description" do
          expect(subject).to be_truthy
          expect(existing_request_issue.reload.edited_description).to eq(edited_description)
        end

        context "if the contention text has been updated in VBMS before" do
          let(:contention_updated_at) { 1.day.ago }

          it "resets contention_updated_at" do
            subject
            expect(existing_request_issue.reload.contention_updated_at).to be_nil
          end
        end
      end

      context "when issues contain new issues not in existing issues" do
        let(:request_issues_data) { request_issues_data_with_new_issue }

        it "saves update, adds issues, and calls create contentions" do
          allow_create_contentions
          allow_associate_rating_request_issues
          expect(review).to receive(:create_business_line_tasks!).once

          expect(subject).to be_truthy
          request_issues_update.reload
          expect(request_issues_update.before_request_issue_ids).to contain_exactly(
            *existing_request_issues.map(&:id)
          )

          expect(request_issues_update.withdrawn_request_issue_ids).to eq([])

          expect(request_issues_update.after_request_issue_ids).to contain_exactly(
            *(existing_request_issues.map(&:id) + [RequestIssue.last.id])
          )

          expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
            hash_including(
              veteran_file_number: review.veteran_file_number,
              contentions: array_including(
                description: "Service connection for cancer was denied",
                contention_type: Constants.CONTENTION_TYPES.higher_level_review
              )
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

          created_issue = review.request_issues.find_by(contested_rating_issue_reference_id: "issue3")
          expect(created_issue).to have_attributes(
            contested_issue_description: "Service connection for cancer was denied"
          )
          expect(created_issue.contention_reference_id).to_not be_nil
        end

        context "with rating control correction request issue" do
          let(:request_issue_to_correct) { review.request_issues.last }

          let(:request_issues_data) do
            [{ request_issue_id: request_issue_to_correct.id,
               correction_type: "control" }]
          end

          let(:review) do
            create(:higher_level_review,
                   veteran_file_number: veteran.file_number,
                   informal_conference: true)
          end

          it "adds new end product for a correction" do
            allow_create_contentions
            expect(EndProductEstablishment.find_by(code: "930AMAHRC", source: review)).to eq(nil)

            subject

            expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
              hash_including(
                veteran_file_number: review.veteran_file_number,
                contentions: array_including(
                  hash_including(
                    description: request_issue_to_correct.description,
                    contention_type: Constants.CONTENTION_TYPES.higher_level_review
                  )
                )
              )
            )
            ep = EndProductEstablishment.find_by(code: "930AMAHRC", source: review)
            expect(ep).to_not be_nil
            correction_request_issue_id = request_issue_to_correct.reload.corrected_by_request_issue_id
            expect(correction_request_issue_id).to_not be_nil
            correction_issue = review.request_issues.find_by(id: correction_request_issue_id)
            expect(correction_issue.end_product_establishment).to eq ep
            expect(correction_issue.correction_type).to eq "control"
          end
        end

        context "with nonrating request issue" do
          let(:request_issues_data) do
            review.request_issues.map { |issue| { request_issue_id: issue.id } } + [{
              decision_text: "Nonrating issue",
              nonrating_issue_category: "Apportionment",
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
            ep = EndProductEstablishment.find_by(
              code: "030HLRNR", source: review, user_id: edit_user.id, station: edit_user.station_id
            )
            expect(ep).to_not be_nil
            # informal conference should also have been created
            expect(ep.development_item_reference_id).to_not be_nil
          end
        end
      end

      context "when issues contain a subset of existing issues" do
        # remove issue with legacy opt in
        let(:request_issues_data) { [{ request_issue_id: existing_request_issue.id }] }

        let(:nonrating_end_product_establishment) do
          create(
            :end_product_establishment,
            veteran_file_number: veteran.file_number,
            source: review,
            code: "030HLRNR",
            user_id: edit_user.id
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
          expect(review).to_not receive(:create_business_line_tasks!)

          expect(subject).to be_truthy

          request_issues_update.reload
          expect(request_issues_update.before_request_issue_ids).to contain_exactly(
            *existing_request_issues.map(&:id)
          )

          expect(request_issues_update.after_request_issue_ids).to contain_exactly(
            existing_request_issue.id
          )

          expect(existing_legacy_opt_in_request_issue.reload.contention_removed_at).to_not be_nil
          expect(existing_legacy_opt_in_request_issue).to be_closed
          expect(existing_legacy_opt_in_request_issue).to be_removed
          expect(existing_legacy_opt_in_request_issue.legacy_issue_optin.rollback_processed_at).to_not be_nil

          expect(Fakes::VBMSService).to have_received(:remove_contention!).with(request_issue_contentions.last)

          new_map = rating_end_product_establishment.reload.send(
            :rating_issue_contention_map,
            review.reload.request_issues.active
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
            decision_review: review,
            end_product_establishment: nonrating_end_product_establishment,
            contention_reference_id: nonrating_request_issue_contention.id,
            nonrating_issue_description: nonrating_request_issue_contention.text,
            nonrating_issue_category: "Apportionment"
          )

          expect_any_instance_of(Fakes::BGSService).to receive(:cancel_end_product).with(
            veteran.file_number,
            "030HLRNR",
            "030",
            "00",
            "1"
          )

          allow_remove_contention
          allow_associate_rating_request_issues

          # reload to pick up new nonrating request issue
          review.request_issues.reload
          expect(subject).to be_truthy

          # expect end product to be canceled
          found_nonrating_ep = EndProductEstablishment.find_by(
            id: nonrating_end_product_establishment.id,
            synced_status: "CAN"
          )
          expect(found_nonrating_ep).to_not be_nil
        end

        context "with decision issues" do
          let!(:deleted_decision_issue) do
            create(:decision_issue,
                   request_issues: [existing_legacy_opt_in_request_issue],
                   participant_id: veteran.participant_id)
          end

          it "deletes associated decision issues" do
            expect(subject).to be_truthy

            expect(RequestDecisionIssue.find_by(
                     request_issue_id: existing_legacy_opt_in_request_issue.id,
                     decision_issue_id: deleted_decision_issue.id
                   )).to be_nil

            expect(DecisionIssue.find_by(id: deleted_decision_issue.id)).to be_nil
          end

          context "with decision issue connected to multiple request issues" do
            let!(:not_deleted_decision_issue) do
              create(:decision_issue,
                     request_issues: [
                       existing_request_issue,
                       existing_legacy_opt_in_request_issue
                     ],
                     participant_id: veteran.participant_id)
            end

            it "does not delete decision issues associated with undeleted request issue" do
              expect(subject).to be_truthy

              expect(RequestDecisionIssue.find_by(
                       request_issue_id: existing_legacy_opt_in_request_issue.id,
                       decision_issue_id: deleted_decision_issue.id
                     )).to be_nil

              expect(DecisionIssue.find_by(id: deleted_decision_issue.id)).to be_nil

              # record associating not_deleted_decision_issue with the deleted request issue
              # should be deleted
              expect(RequestDecisionIssue.find_by(
                       request_issue_id: existing_legacy_opt_in_request_issue.id,
                       decision_issue_id: not_deleted_decision_issue.id
                     )).to be_nil

              expect(RequestDecisionIssue.find_by(
                       request_issue_id: existing_request_issue.id,
                       decision_issue_id: not_deleted_decision_issue.id
                     )).to_not be_nil

              expect(DecisionIssue.find_by(id: not_deleted_decision_issue.id)).to_not be_nil
            end
          end
        end
      end

      context "when an issue is withdrawn" do
        let(:request_issues_data) do
          [{ request_issue_id: existing_legacy_opt_in_request_issue.id, withdrawal_date: Time.zone.now },
           { request_issue_id: existing_request_issue.id }]
        end

        it "withdraws issue, removes contention, and does not rollback legacy issue opt in" do
          allow_remove_contention
          allow_associate_rating_request_issues

          expect(subject).to be_truthy

          request_issues_update.reload
          expect(request_issues_update.before_request_issue_ids).to contain_exactly(
            *existing_request_issues.map(&:id)
          )

          expect(request_issues_update.after_request_issue_ids).to contain_exactly(
            *existing_request_issues.map(&:id)
          )

          expect(request_issues_update.withdrawn_request_issue_ids).to contain_exactly(
            existing_legacy_opt_in_request_issue.id
          )

          expect(existing_legacy_opt_in_request_issue.reload.decision_review).to_not be_nil
          expect(existing_legacy_opt_in_request_issue.contention_removed_at).to_not be_nil
          expect(existing_legacy_opt_in_request_issue).to be_closed
          expect(existing_legacy_opt_in_request_issue).to be_withdrawn
          expect(existing_legacy_opt_in_request_issue.legacy_issue_optin.rollback_processed_at).to be_nil

          expect(Fakes::VBMSService).to have_received(:remove_contention!).with(request_issue_contentions.last)

          new_map = rating_end_product_establishment.reload.send(
            :rating_issue_contention_map,
            review.reload.request_issues.active
          )

          expect(Fakes::VBMSService).to have_received(:associate_rating_request_issues!).with(
            claim_id: rating_end_product_establishment.reference_id,
            rating_issue_contention_map: new_map
          )

          expect(review.request_issues.first.rating_issue_associated_at).to eq(Time.zone.now)

          # ep should not be canceled because 1 rating request issue still exists
          expect(rating_end_product_establishment.reload.synced_status).to eq(nil)
        end

        context "when an issue is withdrawn and there are active tasks" do
          let(:request_issues_data) do
            [{ request_issue_id: existing_legacy_opt_in_request_issue.id, withdrawal_date: Time.zone.now }]
          end

          let!(:in_progress_task) do
            create(:higher_level_review_task, :in_progress, appeal: review)
          end

          context "there are no more active issues" do
            it "closes the end product establishment and cancels any active tasks" do
              expect(subject).to be_truthy
              expect(rating_end_product_establishment.reload.synced_status).to eq("CAN")
              expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
            end
          end

          context "there are active issues remaining" do
            let(:request_issues_data) do
              [{ request_issue_id: existing_legacy_opt_in_request_issue.id, withdrawal_date: Time.zone.now },
               { request_issue_id: existing_request_issue.id }]
            end

            it "does not cancel all active tasks" do
              expect(subject).to be_truthy
              expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.in_progress)
            end
          end
        end

        context "when remove_contention raises VBMS service error and is re-tried" do
          let(:request_issues_data) do
            [{ request_issue_id: existing_legacy_opt_in_request_issue.id, withdrawal_date: Time.zone.now }]
          end

          it "saves error message, logs error and removes contention on re-attempt" do
            capture_raven_log
            raise_error_on_remove_contention

            subject

            expect(request_issues_update.error).to eq(vbms_error.inspect)
            expect(@raven_called).to eq(true)

            withdrawn_issue = request_issues_update.withdrawn_issues.first

            expect(withdrawn_issue).to_not be_nil
            expect(withdrawn_issue).to have_attributes(
              closed_status: "withdrawn",
              closed_at: Time.zone.now,
              contention_removed_at: nil
            )

            allow_remove_contention
            DecisionReviewProcessJob.perform_now(request_issues_update)

            expect(request_issues_update.processed_at).to eq Time.zone.now
            expect(withdrawn_issue.reload.contention_removed_at).to eq Time.zone.now
          end
        end
      end

      context "when create_contentions raises VBMS service error" do
        let(:request_issues_data) { request_issues_data_with_new_issue }

        it "saves error message and logs error" do
          capture_raven_log
          raise_error_on_create_contentions

          subject

          expect(request_issues_update.error).to eq(vbms_error.inspect)
          expect(@raven_called).to eq(true)
        end
      end

      context "when we add and remove unidentified issues" do
        let(:request_issues_data) do
          request_issues = []
          10.times do
            issue = create(:request_issue, :unidentified, decision_review: review)
            request_issues << { is_unidentified: true, decision_text: issue.unidentified_issue_text }
          end
          request_issues
        end

        it "does not re-use contention_reference_id" do
          # start with existing rating request issues
          expect(review.reload.request_issues.pluck(:contention_reference_id).compact.uniq.count).to eq(2)
          subject
          review.reload
          expect(review.request_issues.pluck(:contention_reference_id).compact.uniq.count).to eq(12)
          # only unidentified are left
          expect(review.request_issues.active.count).to eq(10)
        end
      end

      context "when we remove and add the same rating issue" do
        let(:request_issues_data) do
          existing_request_issues.map do |ri|
            {
              rating_issue_reference_id: ri.contested_rating_issue_reference_id,
              rating_issue_profile_date: ri.contested_rating_issue_profile_date,
              decision_text: ri.contested_issue_description
            }
          end
        end

        it "does not re-use contention_reference_id" do
          expect(review.request_issues.pluck(:contention_reference_id).compact.uniq.count).to eq(2)
          subject
          review.reload
          expect(review.request_issues.pluck(:contention_reference_id).compact.uniq.count).to eq(4)
          expect(review.request_issues.active.count).to eq(2)
        end
      end

      context "if remaining issues after update are ineligible" do
        let!(:in_progress_task) { create(:higher_level_review_task, :in_progress, appeal: review) }
        let!(:after_issue) do
          create(:request_issue,
                 :ineligible,
                 decision_review: review,
                 contention_reference_id: "2")
        end
        let!(:request_issues_update) do
          create(:request_issues_update,
                 :requires_processing,
                 review: review,
                 withdrawn_request_issue_ids: nil,
                 before_request_issue_ids: review.request_issues.map(&:id),
                 after_request_issue_ids: [after_issue.id])
        end

        it "should cancel tasks" do
          subject
          expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
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

      def raise_error_on_remove_contention
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_raise(vbms_error)
      end

      def allow_remove_contention
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original
      end
    end
  end

  context "#establish!" do
    let!(:before_issue) { create(:request_issue_with_epe, decision_review: review, contention_reference_id: "1") }
    let!(:after_issue) { create(:request_issue_with_epe, decision_review: review, contention_reference_id: "2") }
    let(:edited_issue) do
      create(
        :request_issue_with_epe,
        decision_review: review,
        contention_reference_id: edited_issue_contention_id,
        edited_description: edited_description
      )
    end
    let(:edited_issue_contention_id) { "3" }

    let!(:riu) do
      create(:request_issues_update, :requires_processing,
             review: review,
             withdrawn_request_issue_ids: nil,
             before_request_issue_ids: [before_issue.id],
             after_request_issue_ids: [after_issue.id],
             edited_request_issue_ids: [edited_issue.id])
    end

    let!(:before_issue_contention) do
      Generators::Contention.build(
        claim_id: before_issue.end_product_establishment.reference_id,
        text: "request issue",
        id: "1"
      )
    end

    let!(:after_issue_contention) do
      Generators::Contention.build(
        claim_id: after_issue.end_product_establishment.reference_id,
        text: "request issue",
        id: "2"
      )
    end

    let!(:edited_issue_contention) do
      Generators::Contention.build(
        claim_id: edited_issue.end_product_establishment.reference_id,
        text: "old request issue description",
        id: edited_issue_contention_id,
        start_date: Time.zone.now,
        submit_date: 5.days.ago
      )
    end

    before { allow_update_contention }

    subject { riu.establish! }

    it "should be successful and update contentions in VBMS" do
      expect(subject).to be_truthy

      updated_contention = edited_issue_contention
      updated_contention.text = edited_description
      expect(Fakes::VBMSService).to have_received(:update_contention!).with(updated_contention)
      expect(edited_issue.reload.contention_updated_at).to eq(Time.zone.now)
    end

    context "when the request issue doesn't have a contention" do
      let(:edited_issue_contention) { nil }
      let(:edited_issue) { create(:request_issue, decision_review: review, edited_description: edited_description) }

      it "does not try to update the contention in VBMS" do
        expect(subject).to be_truthy
        expect(Fakes::VBMSService).to_not have_received(:update_contention!)
        expect(edited_issue.reload.contention_updated_at).to be nil
      end
    end
  end

  context "async logic scopes" do
    let!(:riu_requiring_processing) do
      create(:request_issues_update, :requires_processing)
    end

    let!(:riu_processed) do
      create(:request_issues_update).tap(&:processed!)
    end

    let!(:riu_recently_attempted) do
      create(
        :request_issues_update,
        attempted_at: (RequestIssuesUpdate.processing_retry_interval_hours - 1).hours.ago
      )
    end

    let!(:riu_attempts_ended) do
      create(
        :request_issues_update,
        last_submitted_at: (RequestIssuesUpdate::REQUIRES_PROCESSING_WINDOW_DAYS + 5).days.ago,
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
end
