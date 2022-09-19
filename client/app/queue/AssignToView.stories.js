import React from 'react';
import { MemoryRouter, Route } from 'react-router';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import {
  returnToOrgData,
  emoToBvaIntakeData,
  camoToProgramOfficeToCamoData,
  vhaPOToCAMOData
} from '../../test/data/queue/taskActionModals/taskActionModalData';
import {
  BVA_INTAKE_RETURN_TO_CAMO,
  BVA_INTAKE_RETURN_TO_CAREGIVER,
  BVA_INTAKE_RETURN_TO_EMO,
  VHA_ASSIGN_TO_PROGRAM_OFFICE,
  VHA_ASSIGN_TO_REGIONAL_OFFICE,
  EMO_ASSIGN_TO_RPO
} from '../../constants/TASK_ACTIONS';
import {
  createQueueReducer,
  getAppealId,
  getTaskId
} from '../../test/app/queue/components/modalUtils';
import AssignToView from './AssignToView';

export default {
  title: 'Queue/Components/Task Action Modals/AssignToView',
  component: AssignToView,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  }
};

const Template = (args) => {
  const { storeValues, taskType, modalType, assigneeAlreadySelected } = args;

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
          return <AssignToView {...props.match.params} assigneeAlreadySelected={assigneeAlreadySelected ?? true} />;
        }} path={`/queue/appeals/:appealId/tasks/:taskId/modal/${modalType}`} />
      </MemoryRouter>
    </Provider>
  );
};

export const BvaIntakeReturnsToVhaCamo = Template.bind({});
BvaIntakeReturnsToVhaCamo.args = {
  storeValues: returnToOrgData,
  taskType: 'PreDocketTask',
  modalType: BVA_INTAKE_RETURN_TO_CAMO.value
};

export const BvaIntakeReturnsToVhaCaregiverSupportProgram = Template.bind({});
BvaIntakeReturnsToVhaCaregiverSupportProgram.args = {
  storeValues: returnToOrgData,
  taskType: 'PreDocketTask',
  modalType: BVA_INTAKE_RETURN_TO_CAREGIVER.value
};

export const BvaIntakeReturnsToEmo = Template.bind({});
BvaIntakeReturnsToEmo.args = {
  storeValues: returnToOrgData,
  taskType: 'PreDocketTask',
  modalType: BVA_INTAKE_RETURN_TO_EMO.value
};

export const VhaCamoToVhaPo = Template.bind({});
VhaCamoToVhaPo.args = {
  storeValues: camoToProgramOfficeToCamoData,
  taskType: 'VhaDocumentSearchTask',
  modalType: VHA_ASSIGN_TO_PROGRAM_OFFICE.value,
  assigneeAlreadySelected: false
};

export const VhaPoToVisn = Template.bind({});
VhaPoToVisn.args = {
  storeValues: vhaPOToCAMOData,
  taskType: 'AssessDocumentationTask',
  modalType: VHA_ASSIGN_TO_REGIONAL_OFFICE.value,
  assigneeAlreadySelected: false
};

export const EmoToEducationRpo = Template.bind({});
EmoToEducationRpo.args = {
  storeValues: emoToBvaIntakeData,
  taskType: 'EducationDocumentSearchTask',
  modalType: EMO_ASSIGN_TO_RPO.value,
  assigneeAlreadySelected: false
};
