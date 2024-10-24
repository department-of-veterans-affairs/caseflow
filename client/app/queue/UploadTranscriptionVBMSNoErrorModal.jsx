import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import TextareaField from '../components/TextareaField';

import { highlightInvalidFormItems, requestPatch } from './uiReducer/uiActions';
import { setAppealAttrs, onReceiveAmaTasks } from './QueueActions';

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
      instructions: '',
    };
  }

  validateForm = () => Boolean(this.state.instructions);

  prependUrlToInstructions = () => {
    return this.state.instructions;
  };

  buildPayload = () => {
    return {
      data: {
        task: {
          instructions: this.prependUrlToInstructions()
        }
      }
    };
  }

  submit = () => {
    const { task } = this.props;
    const payload = this.buildPayload();

    return this.props.requestPatch(`/tasks/${task.taskId}/upload_transcription_to_vbms`, payload).
      then((response) => {
        this.props.onReceiveAmaTasks({ amaTasks: response.body.tasks.data });
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  actionForm = () => {
    const { instructions } = this.state;

    return <React.Fragment>
      <div>
        <div>{COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT}</div>
        <div {...marginTop(4)}>
          <TextareaField
            name={COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT_AREA}
            onChange={(value) => this.setState({ instructions: value })}
            placeholder= "This is the reason this is being put on hold."
            value={instructions} />
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
  appealId: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  highlightInvalidFormItems: PropTypes.func,
  onReceiveAmaTasks: PropTypes.func,
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
  highlightInvalidFormItems,
  requestPatch,
  onReceiveAmaTasks,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UploadTranscriptionVBMSNoErrorModal));
