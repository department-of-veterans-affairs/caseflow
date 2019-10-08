class AddPoaParticipantIdToAppeal < ActiveRecord::Migration[5.1]
  def change
    add_column(
      :appeals,
      :poa_participant_id,
      :string,
      comment: "Used to identify the power of attorney (POA) at the time the " \
               "appeal was dispatched to BVA. Sometimes the POA changes in BGS " \
               "after the fact, and BGS only returns the current representative."
    )
  end
end
