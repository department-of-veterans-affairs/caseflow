// @flow
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import Modal from '../../components/Modal';

import {
  getTasksForAppeal,
  getActiveModalType,
  appealWithDetailSelector
} from '../selectors';
import { setTaskAttrs } from '../QueueActions';
import {
  hideModal,
  requestPatch
} from '../uiReducer/uiActions';
import { prepareTasksForStore } from '../utils';
import { SEND_TO_LOCATION_MODAL_TYPES } from '../constants';

import type { State } from '../types/state';
import type { Task, Appeal } from '../types/models';

type Params = {|
  task: Task,
  appeal: Appeal,
  appealId: string,
  modalType: string,
|};

type Props = Params & {|
  saveState: boolean,
  history: Object,
  hideModal: typeof hideModal,
  requestPatch: typeof requestPatch,
  setTaskAttrs: typeof setTaskAttrs
|};

const SEND_TO_LOCATION_MODAL_TYPE_ATTRS = {
  [SEND_TO_LOCATION_MODAL_TYPES.attorney]: {
    buildSuccessMsg: (appeal: Appeal, { assignerName }: { assignerName: string}) => ({
      title: sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_CONFIRMATION, appeal.veteranFullName, assignerName),
      detail: sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_CONFIRMATION_DETAIL, assignerName)
    }),
    title: () => COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
    getContent: ({ assignerName }: { assignerName: string }) => <React.Fragment>
      {COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_COPY}&nbsp;
      <b>{sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_COPY_ATTORNEY_NAME, assignerName)}</b>
    </React.Fragment>,
    buttonText: COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_BUTTON
  },
  [SEND_TO_LOCATION_MODAL_TYPES.team]: {
    buildSuccessMsg: (appeal: Appeal, { teamName }: { teamName: string }) => ({
      title: sprintf(
        COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION,
        appeal.veteranFullName, teamName
      )
    }),
    title: ({ teamName }: { teamName: string }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: ({ appeal, teamName }: { appeal: Appeal, teamName: string }) => <React.Fragment>
      {sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, { ...appeal })}&nbsp;
      <strong>{teamName}</strong>.
    </React.Fragment>,
    buttonText: COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
  }
};

class SendToLocationModal extends React.Component<Props> {
  closeModal = () => this.props.hideModal(this.props.modalType);

  getTaskAssignerName = () => {
    const { task: { assignedBy } } = this.props;

    return `${String.fromCodePoint(assignedBy.firstName.codePointAt(0))}. ${assignedBy.lastName}`;
  };

  buildPayload = () => {
    const {
      task,
      modalType
    } = this.props;
    const payload = {};

    if (modalType === SEND_TO_LOCATION_MODAL_TYPES.attorney) {
      payload.assigned_to_id = task.assignedBy.pgId;
    } else if (modalType === SEND_TO_LOCATION_MODAL_TYPES.team) {
      payload.status = 'completed';
    }

    return payload;
  }

  getContentArgs = () => ({
    assignerName: this.getTaskAssignerName(),
    teamName: CO_LOCATED_ADMIN_ACTIONS[this.props.task.action],
    appeal: this.props.appeal
  });

  sendToLocation = () => {
    const {
      task,
      appeal,
      modalType
    } = this.props;
    const payload = {
      data: {
        task: this.buildPayload()
      }
    };
    const successMsg = SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].buildSuccessMsg(appeal, this.getContentArgs());

    this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.closeModal();
        this.props.history.push('/queue');
        this.props.setTaskAttrs(task.externalAppealId, preparedTasks[task.externalAppealId]);
      });
  }

  render = () => {
    const { modalType, saveState } = this.props;

    return <Modal
      title={SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].title(this.getContentArgs())}
      buttons={[{
        classNames: ['usa-button', 'cf-btn-link'],
        name: 'Cancel',
        onClick: this.closeModal
      }, {
        classNames: ['usa-button-primary', 'usa-button-hover'],
        name: SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].buttonText,
        onClick: this.sendToLocation,
        loading: saveState
      }]}
      closeHandler={this.closeModal}>
      {SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].getContent(this.getContentArgs())}
    </Modal>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps),
  modalType: getActiveModalType(state),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideModal,
  requestPatch,
  setTaskAttrs
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(SendToLocationModal)
): React.ComponentType<Params>);
