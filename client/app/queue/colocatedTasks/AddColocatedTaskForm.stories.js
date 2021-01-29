import React from 'react';

import { action } from '@storybook/addon-actions';
import { withKnobs, text, select } from '@storybook/addon-knobs';

import { AddColocatedTaskForm } from './AddColocatedTaskForm';

export default {
  title: 'Queue/Admin Actions/AddColocatedTaskForm',
  component: AddColocatedTaskForm,
  decorators: [withKnobs]
};

export const standard = () => <AddColocatedTaskForm onChange={action('onChange', 'standard')} />;

standard.parameters = {
  docs: {
    storyDescription:
      'This allows a user to specify a particular admin action along with related context/instructions'
  }
};
