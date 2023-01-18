import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import * as React from 'react';

import { onReceiveAmaTasks } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';
import { taskById, appealWithDetailSelector } from './selectors';
import Alert from '../components/Alert';
import COPY from '../../COPY';
import QueueFlowModal from './components/QueueFlowModal';
import TextareaField from '../components/TextareaField';

class CreateChangeHearingDispositionTaskModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedValue: null,
      instructions: ''
    };
  }

  submit = () => {
    const {
      appeal,
      task
    } = this.props;

    const payload = {
      data: {
        tasks: [{
          type: 'ChangeHearingDispositionTask',
          external_id: appeal.externalId,
          parent_id: task.taskId,
          instructions: this.state.instructions
        }]
      }
    };

    const successMsg = {
      title: sprintf(COPY.CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_SUCCESS, appeal.veteranFullName)
    };

    return this.props.requestSave(`/tasks/${task.taskId}/request_hearing_disposition_change`, payload, successMsg).
      then((resp) => {
        this.props.onReceiveAmaTasks(resp.body.tasks);
      }).
      catch((err) => {
        // handle the error from the frontend
        throw err;
      });
  }

  validateForm = () => {
    return this.state.instructions !== '';
  }

  render = () => {
    const { error, highlightFormItems } = this.props;

    return <QueueFlowModal
      title={COPY.CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_TITLE}
      pathAfterSubmit="/queue"
      submit={this.submit}
      validateForm={this.validateForm}
    >
      {error &&
        <Alert title={error.title} type="error">
          {error.detail}
        </Alert>
      }

      <p>{COPY.CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_BODY}</p>

      <TextareaField
        name="Notes"
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.NOTES_ERROR_FIELD_REQUIRED : null}
        id="taskInstructions"
        onChange={(value) => this.setState({ instructions: value })}
        value={this.state.instructions} />

    </QueueFlowModal>;
  }
}

CreateChangeHearingDispositionTaskModal.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  highlightFormItems: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  const { highlightFormItems, messages } = state.ui;

  return {
    highlightFormItems,
    error: messages.error,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(CreateChangeHearingDispositionTaskModal)));
