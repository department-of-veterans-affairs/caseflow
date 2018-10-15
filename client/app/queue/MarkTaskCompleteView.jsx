// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import {
  tasksForAppealAssignedToUserSelector,
  appealWithDetailSelector,
  organizationTasksByAssigneeIdSelector
} from './selectors';
import { setTaskAttrs } from './QueueActions';
import {
  requestPatch,
  resetSuccessMessages
} from './uiReducer/uiActions';
import { prepareTasksForStore } from './utils';

import decisionViewBase from './components/DecisionViewBase';

import {
  fullWidth,
  marginBottom
} from './constants';
import COPY from '../../COPY.json';

import type { State, UiStateMessage } from './types/state';
import type { Task, Appeal } from './types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  task: Task,
  appeal: Appeal,
  error: ?UiStateMessage,
  requestPatch: typeof requestPatch,
  resetSuccessMessages: typeof resetSuccessMessages,
  setTaskAttrs: typeof setTaskAttrs
|};

class MarkTaskCompleteView extends React.Component<Props> {
  validateForm = () => true;

  goToNextStep = () => {
    const {
      task,
      appeal
    } = this.props;

    const successMsg = {
      title: COPY.TASK_MARKED_COMPLETE_NOTICE_TITLE,
      detail: sprintf(COPY.TASK_MARKED_COMPLETE_NOTICE_DETAIL, appeal.veteranFullName)
    };

    const payload = { data: { task: { status: 'completed' } } };

    this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);
        const preparedTasks = prepareTasksForStore(response.tasks.data);

        this.props.setTaskAttrs(task.uniqueId, preparedTasks[task.uniqueId]);
      });
  }

  render = () => <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>Mark task complete</h1>;
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    messages: { error }
  } = state.ui;

  return {
    error,
    task: tasksForAppealAssignedToUserSelector(state, ownProps)[0] || organizationTasksByAssigneeIdSelector(state, ownProps)[0],
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  resetSuccessMessages,
  setTaskAttrs
}, dispatch);

const WrappedComponent = decisionViewBase(MarkTaskCompleteView, {
  hideCancelButton: true,
  continueBtnText: 'Mark complete'
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
