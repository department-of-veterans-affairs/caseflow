import React from 'react';

import { EditIntakeIssuesModal } from './EditIntakeIssuesModal';

export default {
  title: 'Intake/Edit Issues/Edit Intake Issues',
  component: EditIntakeIssuesModal,
  decorators: [],
  parameters: {},
  args: {
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <EditIntakeIssuesModal {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to edit intake issues on the Edit Issues page',
  },
};
