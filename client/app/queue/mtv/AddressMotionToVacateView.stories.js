import React from 'react';

import { v4 as uuidv4 } from 'uuid';
import { StaticRouter, Route } from 'react-router-dom';
import ReduxBase from '../../components/ReduxBase';
import queueReducer, { initialState } from '../reducers';

import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import AddressMotionToVacateView from './AddressMotionToVacateView';

const appealId = uuidv4();
const taskId = '1';
const appeal = {
  externalId: appealId,
  veteranFullName: 'John Doe',
  veteranFileNumber: '123456789',
  veteranInfo: {
    veteran: {
      full_name: 'John Doe',
    },
  },
};

const storyState = {
  appeals: {
    [appealId]: appeal,
  },
  appealDetails: {
    [appealId]: appeal,
  },
  amaTasks: {
    [taskId]: {
      uniqueId: taskId,
      externalAppealId: appealId,
      label: 'Address Motion to Vacate',
      type: 'JudgeAddressMotionToVacateTask',
      instructions: ['I think you should grant vacatur'],
      availableActions: [
        {
          label: 'Address Motion to Vacate',
          value: 'address_motion_to_vacate',
          data: {
            options: [{ label: 'Jane Doe', value: 1 }],
          },
        },
      ],
    },
  },
};

const RouterDecorator = (storyFn) => (
  <StaticRouter
    location={{
      pathname: `/queue/appeals/${appealId}/tasks/1/${
        TASK_ACTIONS.ADDRESS_MOTION_TO_VACATE.value
      }`,
    }}
  >
    <Route
      path={`/queue/appeals/:appealId/tasks/:taskId/${
        TASK_ACTIONS.ADDRESS_MOTION_TO_VACATE.value
      }`}
    >
      {storyFn()}
    </Route>
  </StaticRouter>
);

const ReduxDecorator = (storyFn) => (
  <ReduxBase
    reducer={queueReducer}
    initialState={{ queue: { ...initialState, ...storyState } }}
  >
    {storyFn()}
  </ReduxBase>
);

export default {
  title:
    'Queue/Motions to Vacate/Judge Address Motion to Vacate/AddressMotionToVacateView',
  component: AddressMotionToVacateView,
  decorators: [RouterDecorator, ReduxDecorator],
};

const Template = () => <AddressMotionToVacateView />;

export const Basic = Template.bind({});
