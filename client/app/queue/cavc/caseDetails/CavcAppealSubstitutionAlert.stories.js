import React from 'react';
import { MemoryRouter } from 'react-router';

import { CavcAppealHasSubstitutionAlert } from './CavcAppealHasSubstitutionAlert';

export default {
  title: 'Queue/cavc/caseDetails/CavcAppealHasSubstitutionAlert',
  component: CavcAppealHasSubstitutionAlert,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    targetAppealId: 'abc123',
  },
  argTypes: {},
};

const Template = (args) => (
  <CavcAppealHasSubstitutionAlert {...args} />
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Shown on Case Details page for the source appeal to indicate the existance of a substitution',
  },
};
