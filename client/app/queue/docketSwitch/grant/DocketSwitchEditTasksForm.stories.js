import React from 'react';
import { DocketSwitchEditTasksForm } from './DocketSwitchEditTasksForm';

const tasks = [
  { taskId: 1, appealId: 1, type: 'TaskTypeA', label: 'Task Type A' },
  { taskId: 2, appealId: 1, type: 'TaskTypeB', label: 'Task Type B' },
  { taskId: 3, appealId: 1, type: 'TaskTypeC', label: 'Task Type C' },
];

export default {
  title: 'Queue/Docket Switch/DocketSwitchEditTasksForm',
  component: DocketSwitchEditTasksForm,
  decorators: [
    // AppSegment styling relies on being inside a .cf-content-inside element
    (storyFn) => <div className="cf-content-inside">{storyFn()}</div>,
  ],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    taskListing: tasks,
    docketFrom: 'direct_review',
    docketTo: 'hearing',
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
    type: {
      control: {
        type: 'select',
        options: ['Task Type A', 'Task Type B', 'Task Type C'],
      },
    },
  },
};
const Template = (args) => <DocketSwitchEditTasksForm {...args} />;

export const Basic = Template.bind({});
Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a grant of a docket switch checkout flow ',
  },
};

export const NoExistingTasks = Template.bind({});
NoExistingTasks.args = {
  taskListing: [],
};

export const PreviouslyFilled = Template.bind({});
PreviouslyFilled.args = {
  defaultValues: {
    taskIds: [1, 3],
    newTasks: [
      { type: 'AojColocatedTask', instructions: 'Lorem ipsum and whatnot' },
    ],
  },
};
