import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
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

import { taskActionData, actionNameOfTask } from './utils';
import QueueFlowModal from './components/QueueFlowModal';

class ChangeTaskTypeModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      actionOption: null,
      instructions: ''
    };
  }

  validateForm = () => Boolean(this.state.actionOption) && Boolean(this.state.instructions);

  buildPayload = () => {
    const { actionOption, instructions } = this.state;

    return {
      data: {
        task: {
          action: actionOption.value,
          instructions
        }
      }
    };
  }

  submit = () => {
    const { task } = this.props;
    const { actionOption } = this.state;

    const payload = this.buildPayload();

    const msgTitle = COPY.CHANGE_TASK_TYPE_CONFIRMATION_TITLE;
    const oldTaskType = actionNameOfTask(task);
    const successMsg = {
      title: sprintf(msgTitle, oldTaskType, actionOption.label),
      detail: COPY.CHANGE_TASK_TYPE_CONFIRMATION_DETAIL
    };

    return this.props.requestPatch(`/tasks/${task.taskId}/change_type`, payload, successMsg).
      then((response) => {
        this.props.onReceiveAmaTasks({ amaTasks: response.body.tasks.data });
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  actionForm = () => {
    const { highlightFormItems } = this.props;
    const { instructions, actionOption } = this.state;

    return <React.Fragment>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            errorMessage={highlightFormItems && !actionOption ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type"
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.setState({ actionOption: option })}
            value={actionOption && actionOption.value} />
        </div>
        <div {...marginTop(4)}>
          <TextareaField
            errorMessage={highlightFormItems && !instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
            name={COPY.CHANGE_TASK_TYPE_INSTRUCTIONS_LABEL}
            onChange={(value) => this.setState({ instructions: value })}
            value={instructions} />
        </div>
      </div>
    </React.Fragment>;
  };

  render = () => {
    const { error } = this.props;

    return <QueueFlowModal
      validateForm={this.validateForm}
      submit={this.submit}
      title={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      button={COPY.CHANGE_TASK_TYPE_SUBHEAD}
      pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
    >
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionForm() }
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
