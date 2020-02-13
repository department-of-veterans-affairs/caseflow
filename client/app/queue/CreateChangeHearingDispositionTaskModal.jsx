import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY';

import {
  taskById,
  appealWithDetailSelector
} from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import {
  requestSave
} from './uiReducer/uiActions';

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
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  validateForm = () => {
    return this.state.instructions !== '';
  }

  render = () => {
    const {
      highlightFormItems
    } = this.props;

    return <QueueFlowModal
      title={COPY.CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_TITLE}
      pathAfterSubmit = "/queue"
      submit={this.submit}
      validateForm={this.validateForm}
    >
      <p>{COPY.CREATE_CHANGE_HEARING_DISPOSITION_TASK_MODAL_BODY}</p>

      <TextareaField
        name="Notes"
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
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
  highlightFormItems: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(CreateChangeHearingDispositionTaskModal)));
