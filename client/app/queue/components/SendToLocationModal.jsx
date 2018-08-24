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
  requestSave
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
  history: Object,
  hideModal: typeof hideModal,
  requestSave: typeof requestSave,
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
    buttonText: 'Send back to attorney'
  },
  [SEND_TO_LOCATION_MODAL_TYPES.team]: {
    buildSuccessMsg: (appeal: Appeal, { teamName }: { teamName: string }) => ({
      title: sprintf(
        COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION,
        appeal.veteranFullName, teamName
      )
    }),
    title: ({ teamName }: { teamName: string }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: ({ teamName }: { teamName: string }) => <React.Fragment>
      <p>{sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, teamName)}</p>
    </React.Fragment>,
    buttonText: 'Send action'
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
    teamName: CO_LOCATED_ADMIN_ACTIONS[this.props.task.action]
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

    this.props.requestSave(`/tasks/${task.taskId}`, payload, successMsg, 'patch').
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.props.history.push('/queue');
        this.props.setTaskAttrs(task.externalAppealId, preparedTasks[task.externalAppealId]);
      });
  }

  render = () => {
    const { modalType } = this.props;

    return <Modal
      title={SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].title(this.getContentArgs())}
      buttons={[{
        classNames: ['usa-button', 'cf-btn-link'],
        name: 'Cancel',
        onClick: this.closeModal
      }, {
        classNames: ['usa-button-primary', 'usa-button-hover'],
        name: SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].buttonText,
        onClick: () => {
          this.sendToLocation();
          this.closeModal();
        }
      }]}
      closeHandler={this.closeModal}>
      {SEND_TO_LOCATION_MODAL_TYPE_ATTRS[modalType].getContent(this.getContentArgs())}
    </Modal>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps),
  modalType: getActiveModalType(state)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideModal,
  requestSave,
  setTaskAttrs
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(SendToLocationModal)
): React.ComponentType<Params>);
