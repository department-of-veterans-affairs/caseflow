import React from 'react';

import { EditIntakeIssueModal } from './EditIntakeIssueModal';

export default {
  title: 'Intake/Edit Issues/Edit Intake Issues',
  component: EditIntakeIssueModal,
  decorators: [],
  parameters: {},
  args: {
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <EditIntakeIssueModal {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to edit intake issues on the Edit Issues page',
  },
};
