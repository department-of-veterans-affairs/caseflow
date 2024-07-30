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
import {
  camoToBvaIntakeData,
  caregiverToIntakeData,
  emoToBvaIntakeData,
  rpoToBvaIntakeData,
  vhaPOToCAMOData,
  visnData,
  returnToOrgData
} from '../../../test/data/queue/taskActionModals/taskActionModalData';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import { CompleteTaskModal } from './CompleteTaskModal';

export default {
  title: 'Queue/Components/Task Action Modals/CompleteTaskModal',
  component: CompleteTaskModal,
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
          return <CompleteTaskModal {...props.match.params} modalType={modalType} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

export const DocketAppeal = Template.bind({});
DocketAppeal.args = {
  storeValues: returnToOrgData,
  taskType: 'PreDocketTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.DOCKET_APPEAL.value)
};

export const VhaCamoToBoardIntakeForReview = Template.bind({});
VhaCamoToBoardIntakeForReview.args = {
  storeValues: camoToBvaIntakeData,
  taskType: 'VhaDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_DOCUMENTS_READY_FOR_BVA_INTAKE_REVIEW.value)
};

export const VhaCamoReturnToBoardIntake = Template.bind({});
VhaCamoReturnToBoardIntake.args = {
  storeValues: camoToBvaIntakeData,
  taskType: 'VhaDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_RETURN_TO_BOARD_INTAKE.value)
};

export const VhaPoToVhaCamo = Template.bind({});
VhaPoToVhaCamo.args = {
  storeValues: vhaPOToCAMOData,
  taskType: 'AssessDocumentationTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_PO_SEND_TO_CAMO_FOR_REVIEW.value)
};

export const VhaRoToVhaPo = Template.bind({});
VhaRoToVhaPo.args = {
  storeValues: visnData,
  taskType: 'AssessDocumentationTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_VISN_SEND_TO_VHA_PO_FOR_REVIEW.value)
};

export const VhaCaregiverSupportProgramToBoardIntakeForReview = Template.bind({});
VhaCaregiverSupportProgramToBoardIntakeForReview.args = {
  storeValues: caregiverToIntakeData,
  taskType: 'VhaDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW.value)
};

export const VhaCaregiverSupportProgramReturnToBoardIntake = Template.bind({});
VhaCaregiverSupportProgramReturnToBoardIntake.args = {
  storeValues: caregiverToIntakeData,
  taskType: 'VhaDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE.value)
};

export const EmoToBoardIntakeForReview = Template.bind({});
EmoToBoardIntakeForReview.args = {
  storeValues: emoToBvaIntakeData,
  taskType: 'EducationDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.EMO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.value)
};

export const EmoReturnToBoardIntake = Template.bind({});
EmoReturnToBoardIntake.args = {
  storeValues: emoToBvaIntakeData,
  taskType: 'EducationDocumentSearchTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.EMO_RETURN_TO_BOARD_INTAKE.value)
};

export const EduRpoToBoardIntakeForReview = Template.bind({});
EduRpoToBoardIntakeForReview.args = {
  storeValues: rpoToBvaIntakeData,
  taskType: 'EducationAssessDocumentationTask',
  modalType: trimTaskActionValue(TASK_ACTIONS.EDUCATION_RPO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.value)
};
