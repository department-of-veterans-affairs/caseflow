// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import COPY from '../../../COPY.json';

import Modal from '../../components/Modal';

import { getTasksForAppeal } from '../selectors';
import {
  checkoutStagedAppeal,
  setTaskAssignment
} from '../QueueActions';
import {
  hideModal,
  requestSave
} from '../uiReducer/uiActions';

import type { State } from '../types/state';
import type { Task, Appeal } from '../types/models';

type Params = {|
  task: Task,
  appeal: Appeal,
  appealId: string
|};

type Props = Params & {|
  hideModal: typeof hideModal,
  requestSave: typeof requestSave,
  history: Object,
  setTaskAssignment: typeof setTaskAssignment,
  checkoutStagedAppeal: typeof checkoutStagedAppeal
|};

class SendToAssigningAttorneyModal extends React.Component<Props> {
  closeModal = () => {
    this.props.hideModal('sendToAttorney');
    this.props.checkoutStagedAppeal(this.props.appealId);
  }

  getAttorneyName = () => {
    const { task } = this.props;

    return `${task.assignedBy.firstName[0]}. ${task.assignedBy.lastName}`;
  }

  sendToAttorney = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          type: 'ColocatedTask',
          assigned_to_id: task.assignedBy.pgId
        }
      }
    };
    const attorneyName = this.getAttorneyName();
    const successMsg = {
      title: sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_CONFIRMATION, appeal.veteranFullName, attorneyName),
      detail: sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_CONFIRMATION_DETAIL, attorneyName)
    };

    this.props.requestSave(`/tasks/${task.taskId}`, payload, successMsg, 'patch').
      then(() => {
        this.props.history.push('/queue');
        this.props.setTaskAssignment(task.externalAppealId, task.assignedBy.cssId, task.assignedBy.pgId);
      });
  }

  render = () => <Modal
    title={COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY}
    buttons={[{
      classNames: ['usa-button', 'cf-btn-link'],
      name: 'Cancel',
      onClick: this.closeModal
    }, {
      classNames: ['usa-button-primary', 'usa-button-hover'],
      name: 'Send back to attorney',
      onClick: () => {
        this.sendToAttorney();
        this.closeModal();
      }
    }]}
    closeHandler={this.closeModal}>
    {COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_COPY}&nbsp;
    <b>{sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_COPY_ATTORNEY_NAME, this.getAttorneyName())}</b>
  </Modal>;
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: state.queue.appeals[ownProps.appealId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideModal,
  requestSave,
  setTaskAssignment,
  checkoutStagedAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(SendToAssigningAttorneyModal)
): React.ComponentType<Params>);
