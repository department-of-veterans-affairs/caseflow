# frozen_string_literal: true

describe HelpController, type: :controller do
  let(:user) { build(:user) }

  before do
    allow_any_instance_of(HelpController).to receive(:current_user).and_return(user)
  end


end
