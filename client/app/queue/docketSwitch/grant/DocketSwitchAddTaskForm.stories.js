import React from 'react';
import { DocketSwitchAddTaskForm } from './DocketSwitchAddTaskForm';



const tasks = [
  { taskId: 1, appealId: 1, type: 'TaskTypeA', label: 'Task Type A' },
  { taskId: 2, appealId: 1, type: 'TaskTypeB', label: 'Task Type B' },
  { taskId: 3, appealId: 1, type: 'TaskTypeC', label: 'Task Type C' },
];
export default {
  title: 'Queue/Docket Switch/DocketSwitchAddTaskForm',
  component: DocketSwitchAddTaskForm,
  decorators: [
    // AppSegment styling relies on being inside a .cf-content-inside element
    (storyFn) => <div className="cf-content-inside">{storyFn()}</div>,
  ],
  parameters: {},
  args: {
    appellantName: 'Jane Doe',
    taskListing: tasks,
    docketName: 'Direct Review',
    docketType: 'Hearings',
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
    type: {
      control: { type: 'select', options: ['Task Type A', 'Task Type B', 'Task Type C'] },
    },
  },
};
const Template = (args) => <DocketSwitchAddTaskForm {...args} />;
export const Basic = Template.bind({});
Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a grant of a docket switch checkout flow ',
  },
};