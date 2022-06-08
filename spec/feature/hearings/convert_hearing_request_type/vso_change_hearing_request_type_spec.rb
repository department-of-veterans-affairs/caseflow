# frozen_string_literal: true

RSpec.feature "Convert hearing request type" do
  let!(:appeal) do
    a = create(:appeal, :with_schedule_hearing_tasks, :hearing_docket)
    a.update!(changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.video)
    a
  end

  before do
    vso.add_user(vso_user)
    User.authenticate!(user: vso_user)
  end

  let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
  let!(:vso_user) { create(:user, :vso_role) }

  context "for VSO users" do
    scenario "Convert appeal to Virtual hearing type" do
      step "navigate to the VSO Form" do
        visit "queue/appeals/#{appeal.uuid}"

        expect(page).to have_content("Video")

        click_link("Convert to virtual")

        expect(page).to have_current_path("/queue/appeals/#{appeal.external_id}" \
          "/tasks/#{appeal.tasks.last.id}/#{Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.value}")
      end

      step "fill out the Form" do
        expect(page).to have_content("Convert Hearing To Virtual")
        # TODO: add front end validation checks here once changes are merged
        click_button("Convert Hearing To Virtual")
      end

      step "Confirm success message" do
        expect(page).to have_content(
          "You have successfully converted #{appeal.veteran_full_name}'s hearing to virtual"
        )
        expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)
      end
    end
  end
end
