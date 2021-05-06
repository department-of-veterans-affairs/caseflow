# frozen_string_literal: true

describe HearingRequestTypeConcern do
  let(:readable_central) { LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:central_office] }
  let(:readable_travel) { LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:travel_board] }
  let(:readable_video) { LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:video] }
  let(:readable_virtual) { LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:virtual] }

  context "with a legacy appeal" do
    let(:changed_hearing_request_type) { nil }
    let(:original_hearing_request_type) { nil }
    let!(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: vacols_case,
        changed_hearing_request_type: changed_hearing_request_type,
        original_hearing_request_type: original_hearing_request_type
      )
    end

    context "#formatted_original_hearing_request_type" do
      subject { appeal.formatted_original_hearing_request_type }

      context "when central_office" do
        let(:vacols_case) { create(:case, :central_office_hearing) }

        it "returns the expected value" do
          expect(subject).to eq :central_office
          expect(appeal.readable_original_hearing_request_type).to eq readable_central
        end

        it "does not save the value to original_hearing_request_type" do
          subject
          expect(appeal.reload.original_hearing_request_type).to be_nil
        end
      end

      context "when video" do
        let(:vacols_case) { create(:case, :video_hearing_requested, :travel_board_hearing) }

        it "returns the expected value" do
          expect(subject).to eq :video
          expect(appeal.readable_original_hearing_request_type).to eq readable_video
        end
      end

      context "when travel" do
        let(:vacols_case) { create(:case, :travel_board_hearing) }

        it "returns the expected value" do
          expect(subject).to eq :travel_board
          expect(appeal.readable_original_hearing_request_type).to eq readable_travel
        end
      end
    end

    context "#remember_original_hearing_request_type" do
      subject { appeal.remember_original_hearing_request_type }

      context "when central_office" do
        let(:vacols_case) { create(:case, :central_office_hearing) }

        it "saves the value to original_hearing_request_type" do
          subject
          expect(appeal.original_hearing_request_type).to eq :central_office.to_s
        end
      end

      context "when travel_board" do
        context "when video_hearing_requested is true" do
          let(:vacols_case) { create(:case, :video_hearing_requested, :travel_board_hearing) }
          it "saves the value to original_hearing_request_type" do
            subject
            expect(appeal.original_hearing_request_type).to eq :video.to_s
          end
        end

        context "when video_hearing_requested is false" do
          let(:vacols_case) { create(:case, :travel_board_hearing) }

          it "saves the value to original_hearing_request_type" do
            subject
            expect(appeal.original_hearing_request_type).to eq :travel_board.to_s
          end
        end

        context "when request type overriden in Caseflow to video" do
          let(:changed_hearing_request_type) { HearingDay::REQUEST_TYPES[:video] }
          let(:vacols_case) { create(:case, :travel_board_hearing) }

          it "saves the original request type" do
            subject
            expect(appeal.original_hearing_request_type).to eq :travel_board.to_s
          end
        end

        context "when request type overriden in Caseflow to virtual" do
          let(:changed_hearing_request_type) { HearingDay::REQUEST_TYPES[:virtual] }
          let(:vacols_case) { create(:case, :travel_board_hearing) }

          it "saves the original request type" do
            subject
            expect(appeal.original_hearing_request_type).to eq :travel_board.to_s
          end
        end
      end

      context "when unsupported type" do
        let(:vacols_case) { create(:case, bfhr: "9") }

        it "saves a nil value" do
          subject
          expect(appeal.original_hearing_request_type).to be_nil
        end

        context "original_hearing_request_type already has a value" do
          let(:original_hearing_request_type) { "travel_board" }

          it "doesn't overwrite the saved value with nil" do
            subject
            expect(appeal.original_hearing_request_type).to eq "travel_board"
          end
        end
      end
    end

    context "#current_hearing_request_type" do
      subject { appeal.current_hearing_request_type }

      context "request type is not overriden in Caseflow" do
        context "when central_office" do
          let(:vacols_case) { create(:case, :central_office_hearing) }

          it { is_expected.to eq(:central_office) }

          it "does not save the value to original_hearing_request_type" do
            subject
            expect(appeal.original_hearing_request_type).to be_nil
          end
        end

        context "when travel_board" do
          let(:vacols_case) { create(:case, :video_hearing_requested, :travel_board_hearing) }

          context "when video_hearing_requested" do
            it { is_expected.to eq(:video) }
          end

          context "when video_hearing_requested is false" do
            let(:vacols_case) { create(:case, :travel_board_hearing) }

            it { is_expected.to eq(:travel_board) }
          end
        end
      end

      context "when request type overriden in Caseflow to video" do
        let(:changed_hearing_request_type) { HearingDay::REQUEST_TYPES[:video] }
        let(:vacols_case) { create(:case, :travel_board_hearing) }

        it { is_expected.to eq(:video) }
      end

      context "when request type overriden in Caseflow to virtual" do
        let(:changed_hearing_request_type) { HearingDay::REQUEST_TYPES[:virtual] }
        let(:vacols_case) { create(:case, :travel_board_hearing) }

        it { is_expected.to eq(:virtual) }
      end

      context "when unsupported type" do
        let(:vacols_case) { create(:case, bfhr: "9") }

        it { is_expected.to be_nil }
      end
    end

    context "#readable_previous_hearing_request_type_for_task and #readable_current_hearing_request_type_for_task" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_schedule_hearing_tasks,
          vacols_case: vacols_case,
          changed_hearing_request_type: changed_hearing_request_type
        )
      end
      let(:current_user) { create(:user, roles: ["Edit HearSched"]) }
      let(:vacols_case) { create(:case, :travel_board_hearing) }
      let(:schedule_hearing_task) { appeal.tasks.find_by(type: "ScheduleHearingTask") }

      before do
        HearingsManagement.singleton.add_user(current_user)
      end

      context "when there's one paper trail event" do
        let(:requested_change) do
          {
            status: Constants.TASK_STATUSES.completed,
            business_payloads: {
              values: {
                changed_hearing_request_type: HearingDay::REQUEST_TYPES[:virtual],
                closest_regional_office: "C"
              }
            }
          }
        end

        before do
          # this will create the event
          schedule_hearing_task.update_from_params(requested_change, current_user)
        end

        it "returns changed request type if version is `current`" do
          expect(ChangeHearingRequestTypeTask.count).to eq(1)
          change_request_type_task = appeal.tasks.find_by(type: "ChangeHearingRequestTypeTask")
          current_type = appeal.readable_current_hearing_request_type_for_task(change_request_type_task.id)
          expect(current_type).to eq(readable_virtual)
        end

        it "returns the original request type if version is `prev`" do
          expect(ChangeHearingRequestTypeTask.count).to eq(1)
          change_request_type_task = appeal.tasks.find_by(type: "ChangeHearingRequestTypeTask")
          previous_type = appeal.readable_previous_hearing_request_type_for_task(change_request_type_task.id)
          expect(previous_type).to eq(readable_travel)
        end

        context "there's a previously canceled ChangeHearingRequestTypeTask" do
          let(:canceled_ht) { create(:hearing_task, appeal: appeal) }
          let(:canceled_sht) { create(:schedule_hearing_task, appeal: appeal, parent: canceled_ht) }
          let!(:canceled_chrtt) { create(:change_hearing_request_type_task, appeal: appeal, parent: canceled_sht) }
          # make sure we're referring to the non-canceled tasks
          let(:schedule_hearing_task) do
            appeal.tasks.where("id NOT IN (?)", canceled_sht.id).find_by(type: "ScheduleHearingTask")
          end
          let(:chrtt_id) do
            appeal.tasks.where("id NOT IN (?)", canceled_chrtt.id).find_by(type: "ChangeHearingRequestTypeTask").id
          end

          before do
            canceled_ht.cancel_task_and_child_subtasks
          end

          it "has an appeal with a canceled and completed ChangeHearingRequestTypeTask" do
            expect(ChangeHearingRequestTypeTask.where(status: Constants.TASK_STATUSES.completed).count).to eq(1)
            expect(ChangeHearingRequestTypeTask.where(status: Constants.TASK_STATUSES.cancelled).count).to eq(1)
          end

          it "returns changed request type if version is `current`" do
            current_type = appeal.readable_current_hearing_request_type_for_task(chrtt_id)
            expect(current_type).to eq(readable_virtual)
          end

          it "returns the original request type if version is `prev`" do
            previous_type = appeal.readable_previous_hearing_request_type_for_task(chrtt_id)
            expect(previous_type).to eq(readable_travel)
          end
        end
      end

      context "when there are two paper trail events" do
        let(:changed_hearing_request_type1) { HearingDay::REQUEST_TYPES[:central] }
        let(:changed_hearing_request_type2) { HearingDay::REQUEST_TYPES[:video] }
        let(:requested_change1) do
          {
            status: Constants.TASK_STATUSES.completed,
            business_payloads: {
              values: {
                changed_hearing_request_type: changed_hearing_request_type1,
                closest_regional_office: "C"
              }
            }
          }
        end
        let(:requested_change2) do
          {
            status: Constants.TASK_STATUSES.completed,
            business_payloads: {
              values: {
                changed_hearing_request_type: changed_hearing_request_type2,
                closest_regional_office: nil
              }
            }
          }
        end

        before do
          # this will create the first event
          schedule_hearing_task.update_from_params(requested_change1, current_user)

          # this will create the second event
          schedule_hearing_task.update_from_params(requested_change2, current_user)
        end

        it "returns changed request type if version is `current`" do
          expect(ChangeHearingRequestTypeTask.count).to eq(2)
          change_request_type_tasks = appeal.tasks.of_type(:ChangeHearingRequestTypeTask)

          # Set the changed request types
          first_request_type = appeal
            .readable_current_hearing_request_type_for_task(change_request_type_tasks.first.id)
          second_request_type = appeal
            .readable_current_hearing_request_type_for_task(change_request_type_tasks.last.id)

          expect(first_request_type).to eq(readable_central)
          expect(second_request_type).to eq(readable_video)
        end

        it "returns the original request type if version is `prev`" do
          expect(ChangeHearingRequestTypeTask.count).to eq(2)

          change_request_type_tasks = appeal.tasks.of_type(:ChangeHearingRequestTypeTask)

          # Set the changed request types
          first_request_type = appeal
            .readable_previous_hearing_request_type_for_task(change_request_type_tasks.first.id)
          second_request_type = appeal
            .readable_previous_hearing_request_type_for_task(change_request_type_tasks.last.id)

          expect(first_request_type).to eq(readable_travel)
          expect(second_request_type).to eq(readable_central)
        end

        context "when a task id that's not on the appeal is passed" do
          it "returns the original request type" do
            bad_task_id = appeal.tasks.order(:id).pluck(:id).last + 1
            previous_request_type = appeal.readable_previous_hearing_request_type_for_task(bad_task_id)
            current_request_type = appeal.readable_current_hearing_request_type_for_task(bad_task_id)
            expect(previous_request_type).to eq readable_travel
            expect(current_request_type).to eq readable_travel
          end
        end
      end

      context "when paper trail event is nil" do
        let(:vacols_case) { create(:case, :central_office_hearing) }

        it { expect(appeal.readable_previous_hearing_request_type_for_task(nil)).to eq(nil) }
        it { expect(appeal.readable_current_hearing_request_type_for_task(nil)).to eq(nil) }
      end
    end
  end

  context "with an ama appeal" do
    let(:closest_regional_office) { nil }
    let!(:appeal) do
      create(
        :appeal,
        closest_regional_office: closest_regional_office
      )
    end

    context "#formatted_original_hearing_request_type" do
      subject { appeal.formatted_original_hearing_request_type }

      context "when closest regional office is the central office" do
        let(:closest_regional_office) { HearingDay::REQUEST_TYPES[:central] }

        it "returns the expected value" do
          expect(subject).to eq :central
          expect(appeal.readable_original_hearing_request_type).to eq readable_central
        end

        it "does not save the value to original_hearing_request_type" do
          subject
          expect(appeal.reload.original_hearing_request_type).to be_nil
        end
      end

      context "when closest regional office is an RO" do
        let(:closest_regional_office) { "RO17" }

        it "returns the expected value" do
          expect(subject).to eq :video
          expect(appeal.readable_original_hearing_request_type).to eq readable_video
        end
      end

      context "when closest regional office is nil" do
        let(:closest_regional_office) { nil }

        it "returns the expected value" do
          expect(subject).to be_nil
          expect(appeal.readable_original_hearing_request_type).to be_nil
        end
      end
    end
  end
end
