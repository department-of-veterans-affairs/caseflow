import React from 'react';
import { MemoryRouter } from 'react-router';

import { AppealHasSubstitutionAlert } from './AppealHasSubstitutionAlert';

export default {
  title: 'Queue/Substitute Appellant/AppealHasSubstitutionAlert',
  component: AppealHasSubstitutionAlert,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    targetAppealId: 'abc123'
  },
  argTypes: {},
};

const Template = (args) => (
  <AppealHasSubstitutionAlert {...args} />
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Shown on Case Details page for the source appeal to indicate the existance of a substitution',
  },
};
