import React from 'react';
import { useArgs } from '@storybook/client-api';
import { MemoryRouter } from 'react-router';

import ReduxBase from 'app/components/ReduxBase';
import reducer, { initialState } from 'app/queue/reducers';

import { AssignToAttorneyWidget } from './AssignToAttorneyWidget';

const RouterDecorator = (Story) => (
  <MemoryRouter>
    <Story />
  </MemoryRouter>
);
const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={{ queue: { ...initialState } }}>
    <Story />
  </ReduxBase>
);

const attorneysOfJudge = [
  { id: 1, full_name: 'Attorney 1' },
  { id: 2, full_name: 'Attorney 2' },
  { id: 3, full_name: 'Attorney 3' },
];
const attorneys = {
  data: [
    ...attorneysOfJudge
  ],
  error: {}
};
const selectedTasks = [
  { appealId: 1, taskId: '1', type: 'JudgeAssignTask', isLegacy: false, label: 'Assign' }
];

export default {
  title: 'Queue/Components/AssignToAttorneyWidget',
  component: AssignToAttorneyWidget,
  args: {
    attorneys,
    attorneysOfJudge,
    selectedTasks
  },
  argTypes: {
    resetSuccessMessages: { action: 'resetSuccessMessages' },
    resetAssignees: { action: 'resetAssignees' },
  }
};

const Template = (args) => {
  // eslint-disable-next-line no-unused-vars
  const [{ selectedAssignee, selectedAssigneeSecondary }, updateArgs] = useArgs();
  const handleSelectedAssignee = ({ assigneeId }) => updateArgs({ selectedAssignee: assigneeId });
  const handleSelectedAssigneeSecondary = ({ assigneeId }) => updateArgs({ selectedAssigneeSecondary: assigneeId });

  return (
    <AssignToAttorneyWidget
      {...args}
      setSelectedAssignee={handleSelectedAssignee}
      setSelectedAssigneeSecondary={handleSelectedAssigneeSecondary}
    />
  );
};

export const Widget = Template.bind({});

export const Modal = Template.bind({});
Modal.args = {
  isModal: true
};
Modal.decorators = [RouterDecorator, ReduxDecorator];

