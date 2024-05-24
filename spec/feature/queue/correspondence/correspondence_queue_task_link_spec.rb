# frozen_string_literal: true

RSpec.feature "Task Links on Your Correspondence and Correspondence Cases pages" do
  include CorrespondenceTaskHelpers

  describe "When a user clicks a task link in veterans details column" do
    let(:inbound_ops_team_user) { create(:user) }
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      InboundOpsTeam.singleton.add_user(inbound_ops_team_user)
      User.authenticate!(user: inbound_ops_team_user)
    end

    context "the task is an active CorrespondenceIntakeTask" do
      it "routes to the Correspondence Intake page" do
        correspondence = create(:correspondence)
        create_correspondence_intake(correspondence, inbound_ops_team_user)
        visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
        find_all("#task-link").last.click
        using_wait_time(10) do
          expect(page).to have_content("Add Related Correspondence")
        end
      end
    end

    context "the task is an active ReviewPackageTask" do
      it "routes to the Review Package page" do
        User.authenticate!(user: inbound_ops_team_user)
        correspondence = create(:correspondence)
        assign_review_package_task(correspondence, inbound_ops_team_user)
        visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
        find_all("#task-link").last.click
        using_wait_time(10) do
          expect(page).to have_content("Review Package")
        end
      end
    end

    context "the task is an EfolderFailedUploadTask" do
      context "with a parent task that is a ReviewPackageTask" do
        it "routes to the Review Package page" do
          User.authenticate!(user: inbound_ops_team_user)
          correspondence = create(:correspondence)
          assign_review_package_task(correspondence, inbound_ops_team_user)
          parent_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
          create_efolderupload_failed_task(correspondence, parent_task)
          visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
          find_all("#task-link").last.click
          using_wait_time(10) do
            expect(page).to have_content("Review Package")
          end
        end
      end

      context "with a parent task that is a CorrespondenceIntakeTask" do
        it "routes to the Correspondence Intake page" do
          User.authenticate!(user: inbound_ops_team_user)
          correspondence = create(:correspondence)
          parent_task = create_correspondence_intake(correspondence, inbound_ops_team_user)
          create_efolderupload_failed_task(correspondence, parent_task)
          visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
          find_all("#task-link").last.click
          using_wait_time(10) do
            expect(page).to have_content("Add Related Correspondence")
          end
        end
      end
    end

    context "the task is a Package Action Task" do
      let(:inbound_ops_team_user) { create(:inbound_ops_team_supervisor) }
      before :each do
        FeatureToggle.enable!(:correspondence_queue)
        InboundOpsTeam.singleton.add_user(inbound_ops_team_user)
        User.authenticate!(user: inbound_ops_team_user)
      end
      context "type ReassignPackageTask" do
        before do
          correspondence = create(:correspondence)
          parent_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
          ReassignPackageTask.create!(
            parent_id: parent_task&.id,
            appeal_id: correspondence&.id,
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton
          )
          visit "/queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
          find_all("#task-link").last.click
        end

        it "user remains on Correspondence Cases" do
          expect(page).to have_content("Correspondence Cases")
        end

        it "a modal appears on the screen" do
          expect(page).to have_css(".cf-modal-body")
        end
      end

      context "type RemovePackageTask" do
        before do
          correspondence = create(:correspondence)
          parent_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
          RemovePackageTask.create!(
            parent_id: parent_task&.id,
            appeal_id: correspondence&.id,
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton
          )
          visit "/queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
          find_all("#task-link").last.click
        end

        it "user remains on Correspondence Cases" do
          expect(page).to have_content("Correspondence Cases")
        end

        it "a modal appears on the screen" do
          expect(page).to have_css(".cf-modal-body")
        end
      end
    end
  end
end
