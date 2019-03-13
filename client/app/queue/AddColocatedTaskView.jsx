import * as React from 'react';
import pluralize from 'pluralize';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import decisionViewBase from './components/DecisionViewBase';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { highlightInvalidFormItems, requestSave } from './uiReducer/uiActions';
import { onReceiveAmaTasks, setAppealAttrs } from './QueueActions';

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
import Button from '../components/Button';

import { taskActionData } from './utils';

const adminActionTemplate = () => {
  return {
    actionLabel: null,
    instructions: '',
    key: _.uniqueId('action_')
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
  }

  updateAdminActionField = (index, key, value) => {
    const fields = [...this.state.adminActions];

    fields[index][key] = value;
    this.setState({ adminActions: fields });
  }

  addAdminActionField = () => {
    this.props.highlightInvalidFormItems(false);
    this.setState({ adminActions: [...this.state.adminActions, adminActionTemplate()] });
  }

  validateForm = () => this.state.adminActions.every(
    (action) => Boolean(action.actionLabel) && Boolean(action.instructions)
  );

  getNextStepUrl = () => taskActionData(this.props).redirect_after;

  buildPayload = () => {
    const { task, appeal } = this.props;

    return this.state.adminActions.map(
      (action) => {
        return {
          label: action.actionLabel,
          instructions: action.instructions,
          type: taskActionData(this.props).type || action.actionLabel,
          external_id: appeal.externalId,
          parent_id: task.isLegacy ? null : task.taskId
        };
      }
    );
  }

  goToNextStep = () => {
    const { task } = this.props;
    const payload = {
      data: {
        tasks: this.buildPayload()
      }
    };
    const msgTitle = COPY.ADD_COLOCATED_TASK_CONFIRMATION_TITLE;
    const msgSubject = pluralize(COPY.ADD_COLOCATED_TASK_CONFIRMATION_SUBJECT, this.state.adminActions.length);
    const msgActions = this.state.adminActions.map((action) =>
      taskActionData(this.props).options.find((option) => option.value === action.actionLabel).label).join(', ');
    const msgDisplayCount = this.state.adminActions.length === 1 ? 'an' : this.state.adminActions.length;
    const successMsg = {
      title: sprintf(msgTitle, msgDisplayCount, msgSubject, msgActions),
      detail: taskActionData(this.props).message_detail || COPY.ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL
    };

    this.props.requestSave('/tasks', payload, successMsg).
      then((resp) => {
        if (task.isLegacy) {
          this.props.setAppealAttrs(task.externalAppealId, { location: 'CASEFLOW' });
        } else {
          const response = JSON.parse(resp.text);

          this.props.onReceiveAmaTasks(response.tasks.data);
        }
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  singleIssueTemplate = (action, total, index) => {
    const { highlightFormItems } = this.props;
    const { instructions, actionLabel, key } = action;

    return <div id={key} key={key}>
      <div {...marginTop(4)}>
        <SearchableDropdown
          errorMessage={highlightFormItems && !actionLabel ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
          placeholder="Select an action type"
          options={taskActionData(this.props).options}
          onChange={(option) => option && this.updateAdminActionField(index, 'actionLabel', option.value)}
          value={actionLabel} />
      </div>
      <div {...marginTop(4)}>
        <TextareaField
          errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          onChange={(value) => this.updateAdminActionField(index, 'instructions', value)}
          value={instructions} />
      </div>
      {total > 1 &&
        <React.Fragment>
          <Button
            willNeverBeLoading
            linkStyling
            styling={css({ paddingLeft: '0' })}
            name={COPY.ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL}
            onClick={() => this.removeAdminActionField(index)} />
          <br />
        </React.Fragment>
      }
      {index === total - 1 &&
        <Button
          dangerStyling
          willNeverBeLoading
          name={COPY.ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL}
          onClick={() => this.addAdminActionField()} />
      }
    </div>;
  };

  actionFormList = (actions) => {
    const total = actions.length;

    return (
      <React.Fragment>
        { actions.map((action, index) => this.singleIssueTemplate(action, total, index)) }
      </React.Fragment>
    );
  }

  render = () => {
    const { error } = this.props;
    const { adminActions } = this.state;

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {COPY.ADD_COLOCATED_TASK_SUBHEAD}
      </h1>
      <hr />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionFormList(adminActions) }
    </React.Fragment>;
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
  requestSave,
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

const WrappedComponent = decisionViewBase(AddColocatedTaskView, {
  hideCancelButton: true,
  continueBtnText: COPY.ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL
});

export default (connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
