import React from 'react';
import faker from 'faker';

import { action } from '@storybook/addon-actions';
import { AddClaimantModal } from './AddClaimantModal';

export default {
  title: 'Intake/AddClaimantModal',
  component: AddClaimantModal,
  decorators: []
};

// Set up sample data & async fn for performing fuzzy search
// Actual implementation performs fuzzy search via backend ruby gem
const totalRecords = 500;
const data = Array.from({ length: totalRecords }, () => ({
  name: faker.name.findName(),
  participant_id: faker.random.number({ min: 600000000, max: 600000000 + totalRecords })
}));
const performQuery = async (search = '') => {
  const regex = RegExp(search, 'i');

  return data.filter((item) => regex.test(item.name));
};

export const standard = () => (
  <AddClaimantModal
    onCancel={action('cancel', 'standard')}
    onSubmit={action('submit', 'standard')}
    onSearch={performQuery}
  />
);

standard.story = {
  parameters: {
    docs: {
      storyDescription: 'This is used to add claimants not already associated with the appeal'
    }
  }
};
