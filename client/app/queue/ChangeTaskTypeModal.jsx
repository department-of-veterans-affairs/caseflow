import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { highlightInvalidFormItems, requestPatch } from './uiReducer/uiActions';
import { setAppealAttrs, onReceiveTasks, deleteTask } from './QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from './selectors';
import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';
import COPY from '../../COPY.json';

import { taskActionData, prepareAllTasksForStore } from './utils';
import QueueFlowModal from './components/QueueFlowModal';

const actionTemplate = () => {
  return {
    actionLabel: null,
    instructions: '',
    key: _.uniqueId('action_')
  };
};

class ChangeTaskTypeModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      action: [actionTemplate()]
    };
  }

  updateActionField = (key, value) => {
    const fields = [...this.state.action];

    fields[key] = value;
    this.setState({ actions: fields });
  }

  validateForm = () => Boolean(this.state.action.actionLabel) && Boolean(this.state.action.instructions);

  buildPayload = () => {
    const { task, appeal } = this.props;
    const { action } = this.state;

    return {
      action: action.actionLabel,
      instructions: action.instructions,
      type: taskActionData(this.props).type || action.actionLabel,
      external_id: appeal.externalId,
      parent_id: task.isLegacy ? null : task.taskId
    };
  }

  submit = () => {
    const { task } = this.props;
    const { action } = this.state;

    const payload = {
      data: {
        tasks: this.buildPayload(),
        role: this.props.role
      }
    };
    const msgTitle = COPY.CHANGE_COLOCATED_TASK_TYPE_CONFIRMATION_TITLE;
    const oldAction = taskActionData(this.props).options.find((option) => option.value === action.actionLabel);
    const successMsg = {
      title: sprintf(msgTitle, oldAction.label, action.label),
      detail: COPY.CHANGE_COLOCATED_TASK_TYPE_CONFIRMATION_DETAIL
    };

    this.props.requestPatch('/tasks', payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        console.log(response.tasks.data);

        // // Remove any duplicate tasks returned by creating multiple admin actions
        // const filteredTasks = _.sortedUniqBy(response.tasks.data, (amaTask) => {
        //   if (amaTask.attributes.external_appeal_id === task.externalAppealId) {
        //     return amaTask.attributes.external_appeal_id;
        //   }

        //   return amaTask.id;
        // });
        // const allTasks = prepareAllTasksForStore(filteredTasks);

        // this.props.onReceiveTasks({
        //   tasks: allTasks.tasks,
        //   amaTasks: allTasks.amaTasks
        // });

        // if (task.isLegacy) {
        //   this.props.setAppealAttrs(task.externalAppealId, { location: 'CASEFLOW' });
        //   this.props.deleteTask(task.uniqueId);
        // }
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  actionForm = (action) => {
    const { highlightFormItems } = this.props;
    const { instructions, actionLabel, key } = action;

    return <React.Fragment>
      <div id={key} key={key}>
        <div {...marginTop(4)}>
          <SearchableDropdown
            errorMessage={highlightFormItems && !actionLabel ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
            placeholder="Select an action type"
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.updateActionField('actionLabel', option.value)}
            value={actionLabel} />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
            errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
            onChange={(value) => this.updateActionField('instructions', value)}
            value={instructions} />
        </div>
      </div>
    </React.Fragment>;
  };

  render = () => {
    const { error, ...otherProps } = this.props;
    const { action } = this.state;

    return <QueueFlowModal
      validateForm={this.validateForm}
      submit={this.submit}
      title="Change task type"
      {...otherProps}
    >
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {COPY.ADD_COLOCATED_TASK_SUBHEAD}
      </h1>
      <hr />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionForm(action) }
    </QueueFlowModal>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  highlightFormItems: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems,
  requestPatch,
  onReceiveTasks,
  deleteTask,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ChangeTaskTypeModal));
