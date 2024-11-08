import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import TextareaField from '../components/TextareaField';

import { requestPatch } from './uiReducer/uiActions';
import { setAppealAttrs } from './QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from './selectors';
import { marginTop } from './constants';
import COPY from '../../COPY';

import QueueFlowModal from './components/QueueFlowModal';

class UploadTranscriptionVBMSNoErrorModal extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      notes: '',
    };
  }

  validateForm = () => Boolean(this.state.notes);

  formatInstructions = () => {
    return [
      COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS,
      COPY.UPLOAD_TRANSCRIPTION_VBMS_NO_ERRORS_ACTION_TYPE,
      this.state.notes
    ];
  };

  buildPayload = () => {
    return {
      data: {
        task: {
          instructions: this.formatInstructions()
        }
      }
    };
  }

  submit = () => {
    const { task, appeal } = this.props;
    const payload = this.buildPayload();

    const successMsg = {
      title: sprintf(COPY.REVIEW_TRANSCRIPTION_VBMS_MESSAGE, appeal.veteranFullName)
    };

    return this.props.requestPatch(`/tasks/${task.taskId}/upload_transcription_to_vbms`, payload, successMsg);
  }

  actionForm = () => {
    const { notes } = this.state;

    return <React.Fragment>
      <div>
        <div>{COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT}</div>
        <div {...marginTop(4)}>
          <TextareaField
            name={COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT_AREA}
            onChange={(value) => this.setState({ notes: value })}
            placeholder= "This is the reason this is being put on hold."
            value={notes} />
        </div>
      </div>
    </React.Fragment>;
  };

  render = () => {
    return <QueueFlowModal
      validateForm={this.validateForm}
      submit={this.submit}
      title={COPY.UPLOAD_TRANSCRIPTION_VBMS_TITLE}
      button={COPY.UPLOAD_TRANSCRIPTION_VBMS_BUTTON}
      pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
      submitButtonClassNames={['usa-button']}
      submitDisabled={!this.validateForm()}
    >
      { this.actionForm() }
    </QueueFlowModal>;
  }
}

UploadTranscriptionVBMSNoErrorModal.propTypes = {
  appeal: PropTypes.shape({
    veteranFullName: PropTypes.string
  }),
  appealId: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  requestPatch: PropTypes.func,
  setAppealAttrs: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    type: PropTypes.string,
  })
};

const mapStateToProps = (state, ownProps) => ({
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UploadTranscriptionVBMSNoErrorModal));
