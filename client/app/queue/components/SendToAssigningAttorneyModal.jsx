// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import COPY from '../../../COPY.json';

import Modal from '../../components/Modal';

import { getTasksForAppeal } from '../selectors';
import { hideModal } from '../uiReducer/uiActions';
import { checkoutStagedAppeal } from '../QueueActions';

import type { State } from '../types/state';
import type { Task } from '../types/models';

type Params = {|
  appealId: string,
  task: Task
|};

type Props = Params & {|
  hideModal: typeof hideModal,
  checkoutStagedAppeal: typeof checkoutStagedAppeal
|};

class SendToAssigningAttorneyModal extends React.Component<Props> {
  closeModal = () => {
    this.props.hideModal('sendToAttorney');
    this.props.checkoutStagedAppeal(this.props.appealId);
  }

  sendToAttorney = () => {
    return true;
  }

  render = () => {
    const { task } = this.props;
    const assignedByFullName = `${task.assignedByFirstName[0]}. ${task.assignedByLastName}`

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
          this.sendToAttorney()
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
  task: getTasksForAppeal(state, ownProps)[0]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideModal,
  checkoutStagedAppeal
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(SendToAssigningAttorneyModal): React.ComponentType<Params>);
