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
  deleteTask
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
  // requestSave: typeof requestSave,
  requestSave: Function,
  deleteTask: typeof deleteTask,
  history: Object,
  checkoutStagedAppeal: typeof checkoutStagedAppeal
|};

class SendToAssigningAttorneyModal extends React.Component<Props> {
  closeModal = () => {
    this.props.hideModal('sendToAttorney');
    this.props.checkoutStagedAppeal(this.props.appealId);
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
          assigned_to_id: task.assignedByPgId
        }
      }
    }
    const successMsg = { title: 'Reassignment success' };

    this.props.requestSave(`/tasks/${task.taskId}`, payload, successMsg, 'patch').
      then(() => {
        this.props.history.push('/queue');
        this.props.deleteTask(task.taskId, appeal.isLegacyAppeal ? 'Legacy' : 'Ama');
      });
  }

  render = () => {
    const { task } = this.props;
    const assignedByFullName = `${task.assignedByFirstName[0]}. ${task.assignedByLastName}`;

    return <Modal
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
      <b>{sprintf(COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY_COPY_ATTORNEY_NAME, assignedByFullName)}</b>
    </Modal>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: state.queue.appeals[ownProps.appealId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideModal,
  deleteTask,
  requestSave,
  checkoutStagedAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(SendToAssigningAttorneyModal)
): React.ComponentType<Params>);
