import * as React from 'react';
import PropTypes from 'prop-types';
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
import COPY from '../../COPY';

import { taskActionData } from './utils';
import QueueFlowModal from './components/QueueFlowModal';
import EfolderUrlField from './components/EfolderUrlField';

class ChangeTaskTypeModal extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      typeOption: null,
      instructions: '',
      eFolderUrl: '',
      eFolderUrlValid: false
    };
  }

  validateForm = () => {
    const instructionsAndValue = () => this.state.typeOption?.value !== null && this.state.instructions !== '';

    if (this.isHearingRequestMailTask()) {
      return instructionsAndValue() && this.state.eFolderUrlValid === true;
    }

    return instructionsAndValue();
  }

  prependUrlToInstructions = () => {

    if (this.isHearingRequestMailTask()) {
      return (`**LINK TO DOCUMENT:** \n ${this.state.eFolderUrl} \n **DETAILS:** \n ${this.state.instructions}`);
    }

    return this.state.instructions;
  };

  buildPayload = () => {
    const { typeOption } = this.state;

    return {
      data: {
        task: {
          type: typeOption.value,
          instructions: this.prependUrlToInstructions()
        }
      }
    };
  }

  submit = () => {
    const { task } = this.props;
    const { typeOption } = this.state;

    const payload = this.buildPayload();

    const successMsg = {
      title: sprintf(COPY.CHANGE_TASK_TYPE_CONFIRMATION_TITLE, task.label, typeOption.label),
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

  isHearingRequestMailTask = () => (this.state.typeOption?.value || '').match(/Hearing.*RequestMailTask/);

  actionForm = () => {
    const { instructions, typeOption } = this.state;

    return <React.Fragment>
      <div>
        <div {...marginTop(4)}>
          <SearchableDropdown
            name={COPY.CHANGE_TASK_TYPE_ACTION_LABEL}
            placeholder="Select an action type"
            options={taskActionData(this.props).options}
            onChange={(option) => option && this.setState({ typeOption: option })}
            value={typeOption && typeOption.value} />
        </div>
        {
          this.isHearingRequestMailTask() &&
          <div>
            <br />
            <EfolderUrlField
              appealId={this.props.appealId}
              requestType={this.state.typeOption?.value}
              onChange={(value, valid) => this.setState({ eFolderUrl: value, eFolderUrlValid: valid })}
            />
          </div>
        }
        <div {...marginTop(4)}>
          <TextareaField
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
      submitButtonClassNames={['usa-button']}
      submitDisabled={!this.validateForm()}
    >
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      { this.actionForm() }
    </QueueFlowModal>;
  }
}

ChangeTaskTypeModal.propTypes = {
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
    label: PropTypes.string
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

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ChangeTaskTypeModal));
