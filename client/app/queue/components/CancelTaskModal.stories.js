import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import {
  createQueueReducer,
  getAppealId,
  getTaskId
} from '../../../test/app/queue/components/modalUtils';
import {
  uiData
} from '../../../test/data/queue/taskActionModals/taskActionModalData';
import { changeHearingRequestTypeTask } from 'test/data';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import CancelTaskModal from './CancelTaskModal';

export default {
  title: 'Queue/Components/Task Action Modals/CancelTaskModal',
  component: CancelTaskModal,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  }
};

const Template = (args) => {
  const { storeValues, taskType, modalType } = args;

  const appealId = getAppealId(storeValues);
  const taskId = getTaskId(storeValues, taskType);

  const queueReducer = createQueueReducer(storeValues);
  const store = createStore(
    queueReducer,
    compose(applyMiddleware(thunk))
  );

  const path = `/queue/appeals/${appealId}/tasks/${taskId}/modal/${modalType}`;

  return (
    <Provider store={store}>
      <MemoryRouter initialEntries={[path]}>
        <Route component={(props) => {
          return <CancelTaskModal {...props.match.params} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

export const CancelChangeHearingRequestTypeTask = Template.bind({});
CancelChangeHearingRequestTypeTask.args = {
  storeValues: {
    queue: {
      amaTasks: {
        ...changeHearingRequestTypeTask,
        type: 'ChangeHearingRequestTypeTask'
      },
      appeals: {
        [changeHearingRequestTypeTask.appealId]: {
          id: changeHearingRequestTypeTask.uniqueId,
          externalId: changeHearingRequestTypeTask.appealId
        }
      }
    },
    ...uiData
  },
  taskType: 'ChangeHearingRequestTypeTask',
  modalType: TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.value
};

export const ReturnCaseToEducationEmoFromRpo = Template.bind({});

export const ReturnCaseToVhaCamoFromVhaPo = Template.bind({});
