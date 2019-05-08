import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';

import { highlightInvalidFormItems, requestPatch } from './uiReducer/uiActions';
import { setAppealAttrs, onReceiveAmaTasks } from './QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from './selectors';
import { marginTop } from './constants';
import COPY from '../../COPY.json';

import { taskActionData } from './utils';
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
      action: actionTemplate()
    };
  }

  updateActionField = (key, value) => {
    const action = { ...this.state.action };

    action[key] = value;
    this.setState({ action });
  }

  validateForm = () => Boolean(this.state.action.actionLabel) && Boolean(this.state.action.instructions);

  buildPayload = () => {
    const { appeal } = this.props;
    const { action } = this.state;

    return {
      action: action.actionLabel,
      instructions: action.instructions,
      type: taskActionData(this.props).type || action.actionLabel,
      external_id: appeal.externalId
    };
  }

  submit = () => {
    const { task } = this.props;
    const { action } = this.state;

    const payload = {
      data: {
        task: this.buildPayload(),
        role: this.props.role
      }
    };
    const msgTitle = COPY.CHANGE_TASK_TYPE_CONFIRMATION_TITLE;
    const oldAction = taskActionData(this.props).options.find((option) => option.value === task.type);
    const newAction = taskActionData(this.props).options.find((option) => option.value === action.actionLabel);
    const successMsg = {
      title: sprintf(msgTitle, oldAction.label, newAction.label),
      detail: COPY.CHANGE_TASK_TYPE_CONFIRMATION_DETAIL
    };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((response) => {
        const amaTasks = JSON.parse(response.text).tasks.data;

        this.props.onReceiveAmaTasks({ amaTasks });
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
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type"
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.updateActionField('actionLabel', option.value)}
            value={actionLabel} />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
            errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.CHANGE_TASK_TYPE_INSTRUCTIONS_LABEL}
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
      title={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      button={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
      {...otherProps}
    >
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
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ChangeTaskTypeModal));
