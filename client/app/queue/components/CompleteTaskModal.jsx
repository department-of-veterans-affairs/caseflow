// @flow
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import { prepareTasksForStore } from '../utils';
import editModalBase from './EditModalBase';

import type { State } from '../types/state';
import type { Task, Appeal } from '../types/models';

type Params = {|
  task: Task,
  taskId: string,
  appeal: Appeal,
  appealId: string,
  modalType: string,
|};

type Props = Params & {|
  saveState: boolean,
  history: Object,
  requestPatch: typeof requestPatch,
  onReceiveAmaTasks: typeof onReceiveAmaTasks
|};

const SEND_TO_LOCATION_MODAL_TYPE_ATTRS = {
  mark_task_complete: {
    buildSuccessMsg: (appeal: Appeal, { assignerName }: { assignerName: string}) => ({
      title: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteranFullName),
      detail: sprintf(COPY.MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, assignerName)
    }),
    title: () => COPY.MARK_TASK_COMPLETE_TITLE,
    getContent: ({ assignerName }: { assignerName: string }) => <React.Fragment>
      {sprintf(COPY.MARK_TASK_COMPLETE_COPY, assignerName)}
    </React.Fragment>,
    buttonText: COPY.MARK_TASK_COMPLETE_BUTTON
  },
  send_colocated_task: {
    buildSuccessMsg: (appeal: Appeal, { teamName }: { teamName: string }) => ({
      title: sprintf(
        COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION,
        appeal.veteranFullName, teamName
      )
    }),
    title: ({ teamName }: { teamName: string }) => sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, teamName),
    getContent: ({ appeal, teamName }: { appeal: Appeal, teamName: string }) => <React.Fragment>
      {sprintf(COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, appeal.veteranFullName, appeal.veteranFileNumber)}&nbsp;
      <strong>{teamName}</strong>.
    </React.Fragment>,
    buttonText: COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
  }
};

class CompleteTaskModal extends React.Component<Props> {
  getTaskAssignerName = () => {
    const { task: { assignedBy } } = this.props;

    // Tasks created by the application (tasks for quality review or dispatch) will not have assigners.
    // TODO: Amend copy to better explain what is going on instead of having a blank field where we expect
    // to see somebody's name.
    if (!assignedBy.firstName.codePointAt(0)) {
      return '';
    }

    return `${String.fromCodePoint(assignedBy.firstName.codePointAt(0))}. ${assignedBy.lastName}`;
  };

  getContentArgs = () => ({
    assignerName: this.getTaskAssignerName(),
    teamName: CO_LOCATED_ADMIN_ACTIONS[this.props.task.action],
    appeal: this.props.appeal
  });

  submit = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          status: 'completed'
        }
      }
    };
    const successMsg = SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].
      buildSuccessMsg(appeal, this.getContentArgs());

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.props.onReceiveAmaTasks(preparedTasks);
      });
  }

  render = () => {
    return this.props.task ? SEND_TO_LOCATION_MODAL_TYPE_ATTRS[this.props.modalType].
      getContent(this.getContentArgs()) : null;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

const propsToText = (props) => {
  return {
    title: SEND_TO_LOCATION_MODAL_TYPE_ATTRS[props.modalType].title({
      teamName: (props.task && props.task.action) ? CO_LOCATED_ADMIN_ACTIONS[props.task.action] : ''
    }),
    button: SEND_TO_LOCATION_MODAL_TYPE_ATTRS[props.modalType].buttonText
  };
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    CompleteTaskModal, { propsToText }
  ))
): React.ComponentType<Params>);
