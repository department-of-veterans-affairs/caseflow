import React from 'react';

import { MemoryRouter } from 'react-router';
import { sub } from 'date-fns';
import uuid from 'uuid';

import { KeyDetails } from './KeyDetails';

export default {
  title: 'Queue/Substitute Appellant/KeyDetails',
  component: KeyDetails,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    appealId: uuid.v4(),
    dateOfDeath: sub(new Date(), { days: 15 }),
    nodDate: sub(new Date(), { days: 30 }),
    substitutionDate: sub(new Date(), { days: 10 }),
  },
  argTypes: {},
};

const Template = (args) => <KeyDetails {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Displays key details about the claim to aid in selecting tasks when substituting an appellant',
  },
};
