import React from 'react';

import { action } from '@storybook/addon-actions';
import { AddClaimantModal } from './AddClaimantModal';

export default {
  title: 'Intake/AddClaimantModal',
  component: AddClaimantModal,
  decorators: []
};

export const standard = () => (
  <AddClaimantModal onCancel={action('cancel', 'standard')} onSubmit={action('submit', 'standard')} />
);

standard.parameters = {
  docs: {
    storyDescription: 'This is used to add claimants not already associated with the appeal'
  }
};
