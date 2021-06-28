import React from 'react';
import { individualClaimant, individualPoa } from 'test/data/intake/claimants';

import { AddClaimantConfirmationModal } from './AddClaimantConfirmationModal';

export default {
  title: 'Intake/Add Claimant/AddClaimantConfirmationModal',
  component: AddClaimantConfirmationModal,
  decorators: [],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onConfirm: { action: 'confirm' },
  },
};

const Template = (args) => <AddClaimantConfirmationModal {...args} />;

export const Individual = Template.bind({});
Individual.args = {
  claimant: individualClaimant,
};
Individual.parameters = {
  docs: {
    storyDescription:
      "This is shown after adding a new claimant or a new claimant's POA",
  },
};

export const WithPoa = Template.bind({});
WithPoa.args = {
  claimant: individualClaimant,
  poa: individualPoa,
};

export const MissingLastName = Template.bind({});
MissingLastName.args = {
  claimant: { ...individualClaimant, lastName: '' },
  poa: individualPoa,
};
