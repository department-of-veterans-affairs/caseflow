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
  visnOnHoldData
} from '../../../test/data/queue/taskActionModals/taskActionModalData';
import EndHoldModel from './EndHoldModal';

export default {
  title: 'Queue/Components/Task Action Modals/EndHoldModel',
  component: EndHoldModel,
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
          return <EndHoldModel {...props.match.params} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

export const EndHoldAndReturnToAssigned = Template.bind({});
EndHoldAndReturnToAssigned.args = {
  storeValues: visnOnHoldData,
  taskType: 'AssessDocumentationTask',
  modalType: 'modal/end_hold'
};

