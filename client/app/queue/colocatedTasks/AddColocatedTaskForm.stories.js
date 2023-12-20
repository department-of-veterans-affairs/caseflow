import React from 'react';

import { AddColocatedTaskForm } from './AddColocatedTaskForm';

export default {
  title: 'Queue/Admin Actions/AddColocatedTaskForm',
  component: AddColocatedTaskForm,
  decorators: [],
  argTypes: {
    onChange: { action: 'onChange' }
  }
};

const Template = (args) => <AddColocatedTaskForm {...args} />;

export const Standard = Template.bind({});

Standard.parameters = {
  docs: {
    storyDescription:
      'This allows a user to specify a particular admin action along with related context/instructions'
  }
};
