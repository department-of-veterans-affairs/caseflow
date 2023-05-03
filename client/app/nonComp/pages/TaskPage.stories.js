import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';

import TaskPage from './TaskPage';

import {
  completeTaskPageData, inProgressTaskPageData
} from '../../../test/data/queue/nonCompTaskPage/nonCompTaskPageData';


const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  return <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
    <Story />
  </ReduxBase>;
};

export default {
  title: 'Queue/NonComp/TaskPage',
  component: TaskPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <TaskPage
      {...args}
    />
  );
};

export const TaskPageCompleted = Template.bind({});
export const TaskPageInProgress = Template.bind({});

TaskPageCompleted.story = {
  name: 'Completed High level Claims'
};

TaskPageCompleted.args = {
  data: {
    ...completeTaskPageData
  }
};

TaskPageInProgress.story = {
  name: 'In Progress High level Claims'
};

TaskPageInProgress.args = {
  data: {
    ...inProgressTaskPageData
  }
};
