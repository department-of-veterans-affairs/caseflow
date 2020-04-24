import * as React from 'react';
import PropTypes from 'prop-types';
import pluralize from 'pluralize';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';
import { uniqueId, sortedUniqBy } from 'lodash';
import { sprintf } from 'sprintf-js';

import Alert from '../../components/Alert';

import { highlightInvalidFormItems, requestSave } from '../uiReducer/uiActions';
import { setAppealAttrs, onReceiveTasks, deleteTask } from '../QueueActions';

import { appealWithDetailSelector, taskById } from '../selectors';
import { fullWidth, marginBottom } from '../constants';
import COPY from '../../../COPY';
import Button from '../../components/Button';

import { taskActionData, prepareAllTasksForStore } from '../utils';
import QueueFlowPage from '../components/QueueFlowPage';
import { AddColocatedTaskForm } from './AddColocatedTaskForm';

export const adminActionTemplate = () => {
  return {
    type: null,
    instructions: '',
    key: uniqueId('action_')
  };
};

class AddColocatedTaskView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      adminActions: [adminActionTemplate()]
    };
  }

  removeAdminActionField = (index) => {
    const fields = [...this.state.adminActions];

    fields.splice(index, 1);
    this.setState({ adminActions: fields });
  };

  updateAdminActionField = (index, value) => {
    const fields = [...this.state.adminActions];

    fields[index] = {
      ...fields[index],
      ...value
    };
    this.setState({ adminActions: fields });
  };

  addAdminActionField = () => {
    this.props.highlightInvalidFormItems(false);
    this.setState({ adminActions: [...this.state.adminActions, adminActionTemplate()] });
  };

  validateForm = () => this.state.adminActions.every((action) => Boolean(action.type) && Boolean(action.instructions));

  getNextStepUrl = () => taskActionData(this.props).redirect_after;

  buildPayload = () => {
    const { task, appeal } = this.props;

    return this.state.adminActions.map((action) => {
      return {
        instructions: action.instructions,
        type: action.type,
        external_id: appeal.externalId,
        parent_id: task.isLegacy ? null : task.taskId
      };
    });
  };

  goToNextStep = () => {
    const { task } = this.props;
    const payload = {
      data: {
        tasks: this.buildPayload(),
        role: this.props.role
      }
    };
    const msgTitle = COPY.ADD_COLOCATED_TASK_CONFIRMATION_TITLE;
    const msgSubject = pluralize(COPY.ADD_COLOCATED_TASK_CONFIRMATION_SUBJECT, this.state.adminActions.length);
    const msgActions = this.state.adminActions.
      map((action) => taskActionData(this.props).options.find((option) => option.value === action.type).label).
      join(', ');
    const msgDisplayCount = this.state.adminActions.length === 1 ? 'an' : this.state.adminActions.length;
    const successMsg = {
      title: sprintf(msgTitle, msgDisplayCount, msgSubject, msgActions),
      detail: taskActionData(this.props).message_detail || COPY.ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL
    };

    this.props.
      requestSave('/tasks', payload, successMsg).
      then((resp) => {
        // Remove any duplicate tasks returned by creating multiple admin actions
        const filteredTasks = sortedUniqBy(resp.body.tasks.data, (amaTask) => {
          if (amaTask.attributes.external_appeal_id === task.externalAppealId) {
            return amaTask.attributes.external_appeal_id;
          }

          return amaTask.id;
        });
        const allTasks = prepareAllTasksForStore(filteredTasks);

        this.props.onReceiveTasks({
          tasks: allTasks.tasks,
          amaTasks: allTasks.amaTasks
        });

        if (task.isLegacy) {
          this.props.setAppealAttrs(task.externalAppealId, { location: 'CASEFLOW' });
          this.props.deleteTask(task.uniqueId);
        }
      }).
      catch(() => {
        // handle the error from the frontend
      });
  };

  singleIssueTemplate = (action, total, index) => {
    const { highlightFormItems } = this.props;
    const { instructions, type, key } = action;

    return (
      <div id={key} key={key}>
        <AddColocatedTaskForm
          actionTypes={taskActionData(this.props).options}
          highlightFormItems={highlightFormItems}
          onChange={(value) => this.updateAdminActionField(index, value)}
          value={{ type, instructions }}
        />
        {total > 1 && (
          <React.Fragment>
            <Button
              willNeverBeLoading
              linkStyling
              styling={css({ paddingLeft: '0' })}
              name={COPY.ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL}
              onClick={() => this.removeAdminActionField(index)}
            />
            <br />
          </React.Fragment>
        )}
        {index === total - 1 && (
          <Button
            dangerStyling
            willNeverBeLoading
            name={COPY.ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL}
            onClick={() => this.addAdminActionField()}
          />
        )}
      </div>
    );
  };

  actionFormList = (actions) => {
    const total = actions.length;

    return (
      <React.Fragment>{actions.map((action, index) => this.singleIssueTemplate(action, total, index))}</React.Fragment>
    );
  };

  render = () => {
    const { error, ...otherProps } = this.props;
    const { adminActions } = this.state;

    return (
      <QueueFlowPage
        validateForm={this.validateForm}
        goToNextStep={this.goToNextStep}
        getNextStepUrl={this.getNextStepUrl}
        continueBtnText={COPY.ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL}
        hideCancelButton
        {...otherProps}
      >
        <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
          {COPY.ADD_COLOCATED_TASK_SUBHEAD}
        </h1>
        <hr />
        {error && (
          <Alert title={error.title} type="error">
            {error.detail}
          </Alert>
        )}
        {this.actionFormList(adminActions)}
      </QueueFlowPage>
    );
  };
}

AddColocatedTaskView.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string
  }),
  deleteTask: PropTypes.func,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  highlightFormItems: PropTypes.bool,
  highlightInvalidFormItems: PropTypes.func,
  onReceiveTasks: PropTypes.func,
  requestSave: PropTypes.func,
  role: PropTypes.string,
  setAppealAttrs: PropTypes.func,
  task: PropTypes.shape({
    externalAppealId: PropTypes.string,
    uniqueId: PropTypes.string,
    taskId: PropTypes.string,
    isLegacy: PropTypes.bool
  })
};

const mapStateToProps = (state, ownProps) => ({
  highlightFormItems: state.ui.highlightFormItems,
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      highlightInvalidFormItems,
      requestSave,
      onReceiveTasks,
      deleteTask,
      setAppealAttrs
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(AddColocatedTaskView)
);
