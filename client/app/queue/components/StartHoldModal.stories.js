import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import {
  createQueueReducer,
  getAppealId,
  getTaskId,
  trimTaskActionValue
} from '../../../test/app/queue/components/modalUtils';
import { vhaPOToCAMOData } from '../../../test/data/queue/taskActionModals/taskActionModalData';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import StartHoldModal from './StartHoldModal';

export default {
  title: 'Queue/Components/Task Action Modals/StartHoldModal',
  component: StartHoldModal,
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
          return <StartHoldModal {...props.match.params} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

export const VhaProgramOfficeSetTaskOnHold = Template.bind({});
VhaProgramOfficeSetTaskOnHold.args = {
  storeValues: vhaPOToCAMOData,
  taskType: 'AssessDocumentationTask',
  modalType: ""
};
