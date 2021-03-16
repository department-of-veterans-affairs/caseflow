import React from 'react';

import ReduxBase from 'app/components/ReduxBase';
import reducer, { initialState } from 'app/queue/reducers';
import { ColocatedTaskListView } from './ColocatedTaskListView';

import { getQueueConfig } from 'test/data/queue/taskLists';
import { MemoryRouter } from 'react-router';

const stateWithConfig = {
  ...initialState,
  queueConfig: getQueueConfig(),
};

const RouterDecorator = (Story) => (
  <MemoryRouter>
    <Story />
  </MemoryRouter>
);

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={{ queue: { ...stateWithConfig } }}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Queue/Components/ColocatedTaskListView',
  component: ColocatedTaskListView,
  decorators: [RouterDecorator, ReduxDecorator],
  args: {},
  argTypes: {
    clearCaseSelectSearch: { action: 'clearCaseSelectSearch' },
    hideSuccessMessage: { action: 'hideSuccessMessage' },
  },
};

const Template = (args) => <ColocatedTaskListView {...args} />;

export const Default = Template.bind({});

export const SuccessAlert = Template.bind({});
SuccessAlert.args = {
  success: {
    title: 'Great Success!',
    detail: 'Lorem ipsum dolor sit amet, consectetur',
  },
};
