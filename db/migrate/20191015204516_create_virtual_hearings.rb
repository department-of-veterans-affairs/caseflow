class CreateVirtualHearings < ActiveRecord::Migration[5.1]
  def change
    create_table :virtual_hearings do |t|
      t.belongs_to :hearing,
                   polymorphic: true,
                   index: true,
                   comment: "Associated hearing"

      t.integer    :conference_id,
                   index: true,
                   comment: "ID of conference from Pexip"
      t.string     :alias, comment: "Alias for conference in Pexip"

      t.integer    :guest_pin, comment: "PIN number for guests of Pexip conference"
      t.integer    :host_pin, comment: "PIN number for host of Pexip conference"

      t.string     :veteran_email, comment: "Veteran's email address"
      t.boolean    :veteran_email_sent,
                   null: false,
                   default: false,
                   comment: "Whether or not a notification email was sent to the veteran"

      t.string     :judge_email, comment: "Judge's email address"
      t.boolean    :judge_email_sent,
                   null: false,
                   default: false,
                   comment: "Whether or not a notification email was sent to the judge"

      t.string     :representative_email, comment: "Veteran's representative's email address"
      t.boolean    :representative_email_sent,
                   null: false,
                   default: false,
                   comment: "Whether or not a notification email was sent to the veteran's representative"

      t.boolean    :conference_deleted,
                   null: false,
                   default: false,
                   comment: "Whether or not the conference was deleted from Pexip"

      t.string     :status,
                   null: false,
                   default: "pending",
                   comment: "The status of the Pexip conference"

      t.belongs_to :created_by,
                   references: :users,
                   null: false,
                   comment: "User who created the virtual hearing"

      t.timestamps
    end
  end
end
