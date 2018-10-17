// @flow
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import {
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector,
  appealWithDetailSelector
} from '../selectors';
import { setTaskAttrs } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import { prepareTasksForStore } from '../utils';
import editModalBase from './EditModalBase';

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
  requestPatch: typeof requestPatch,
  setTaskAttrs: typeof setTaskAttrs
|};

class CancelTaskModal extends React.Component<Props> {
  getTaskAssignerName = () => {
    const { task: { assignedBy } } = this.props;

    return `${String.fromCodePoint(assignedBy.firstName.codePointAt(0))}. ${assignedBy.lastName}`;
  };

  submit = () => {
    const {
      task,
      appeal
    } = this.props;
    const assignerName = this.getTaskAssignerName();
    const payload = {
      data: {
        task: {
          status: 'canceled'
        }
      }
    };
    const successMsg = {
      title: sprintf(COPY.CANCEL_TASK_CONFIRMATION, appeal.veteranFullName, assignerName),
      detail: sprintf(COPY.CANCEL_TASK_CONFIRMATION_DETAIL, assignerName)
    }

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.props.setTaskAttrs(task.uniqueId, preparedTasks[task.uniqueId]);
      });
  }

  render = () => {
    return <React.Fragment>
      {sprintf(COPY.CANCEL_TASK_COPY, assignerName)}
    </React.Fragment>
  };
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: tasksForAppealAssignedToUserSelector(state, ownProps)[0] ||
    incompleteOrganizationTasksByAssigneeIdSelector(state, { appealId: ownProps.appealId })[0],
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskAttrs
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    CancelTaskModal, { title: COPY.CANCEL_TASK_TITLE, button: COPY.CANCEL_TASK_BUTTON }
  ))
): React.ComponentType<Params>);
