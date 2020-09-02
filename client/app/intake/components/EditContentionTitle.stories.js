import React from 'react';

import { EditContentionTitle } from './EditContentionTitle';

export default {
  title: 'Intake/Edit Issues/EditContentionTitle',
  component: EditContentionTitle,
  decorators: [],
  parameters: {
    docs: {},
  },
  args: {
    issue: {
      date: '2020-01-15',
      editedDescription: 'Tinnitus',
      id: 1,
      index: 2,
      notes: '',
      text: 'Tinnitus',
    },
    issueIdx: 2,
  },
  argTypes: {
    setEditContentionText: { action: 'setEditContentionText' }
  },
};

const Template = (args) => <EditContentionTitle {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This allows editing of contention titles on the "Edit Issues" page',
  },
};
