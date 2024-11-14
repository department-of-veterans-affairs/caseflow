class AddPolymorphicAppealAssociationToNotificationsTable < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :notifications, :notifiable, polymorphic: true, index: false
  end
end
