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
  rpoToBvaIntakeData,
  vhaPOToCAMOData
} from '../../../test/data/queue/taskActionModals/taskActionModalData';
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

export const ReturnCaseToEducationEmoFromRpo = Template.bind({});
ReturnCaseToEducationEmoFromRpo.args = {
  storeValues: rpoToBvaIntakeData,
  taskType: 'EducationAssessDocumentationTask',
  modalType: TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value
};

export const ReturnCaseToVhaCamoFromVhaPo = Template.bind({});
ReturnCaseToVhaCamoFromVhaPo.args = {
  storeValues: vhaPOToCAMOData,
  taskType: 'AssessDocumentationTask',
  modalType: TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value
};
