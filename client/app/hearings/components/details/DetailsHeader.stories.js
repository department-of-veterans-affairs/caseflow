import React from 'react';
import { MemoryRouter } from 'react-router';

import { DetailsHeader } from './DetailsHeader';

const RouterDecorator = (Story) => (
  <MemoryRouter>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Hearings/Components/Hearing Details/DetailsHeader',
  component: DetailsHeader,
  decorators: [RouterDecorator],
  args: {
    aod: false,
    disposition: 'held',
    docketName: 'hearing',
    docketNumber: '1234567',
    isVirtual: false,
    hearingDayId: 1,
    readableLocation: 'Regional Office',
    readableRequestType: 'Video',
    regionalOfficeName: 'Regional Office',
    scheduledFor: new Date(),
    veteranFirstName: 'Last',
    veteranLastName: 'First',
    veteranFileNumber: '12345678',
  },
  argTypes: {
    readableRequestType: {
      type: 'select',
      options: ['Central', 'Virtual', 'Video']
    }
  }
};

const Template = (args) => (
  <DetailsHeader {...args} />
);

export const Normal = Template.bind({});
