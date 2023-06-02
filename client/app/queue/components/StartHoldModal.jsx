import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveAmaTasks } from '../QueueActions';
import QueueFlowModal from './QueueFlowModal';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import { sprintf } from 'sprintf-js';
import {
  appealWithDetailSelector,
  taskById
} from '../selectors';
import {
  marginTop,
  CUSTOM_HOLD_DURATION_TEXT,
  COLOCATED_HOLD_DURATIONS,
  VHA_HOLD_DURATIONS,
  marginBottom
} from '../constants';
import { withRouter } from 'react-router-dom';
import {
  requestSave,
  resetErrorMessages,
  resetSuccessMessages,
} from '../uiReducer/uiActions';

import { css } from 'glamor';
import { taskActionData } from '../utils';

const labelTextStyling = css({
  marginBottom: 0
});

/* eslint-disable camelcase */
class StartHoldModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hold: '',
      customHold: null,
      instructions: ''
    };
  }

  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  };

  isVHAHold = () => Boolean(this.props.task.type === 'AssessDocumentationTask');

  holdLength = () => this.state.hold === CUSTOM_HOLD_DURATION_TEXT ? this.state.customHold : this.state.hold;

  validateForm = () => {
    const hasInstructions = Boolean(this.state.instructions);
    const hasHoldLength = Boolean(Number(this.holdLength()));
    const customHoldIsValid = Boolean(this.state.customHold < 46);

    if (this.isVHAHold()) {
      return hasInstructions && hasHoldLength && customHoldIsValid;
    }

    return hasInstructions && hasHoldLength;
  };

  submit = () => {
    const {
      appeal,
      task
    } = this.props;

    const successMsg = {
      title: sprintf(COPY.COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, appeal.veteranFullName, this.holdLength()),
      detail: COPY.COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION_DETAIL
    };

    const payload = {
      data: {
        task: {
          days_on_hold: this.holdLength(),
          instructions: this.state.instructions
        }
      }
    };

    return this.props.requestSave(`/tasks/${task.taskId}/place_hold`, payload, successMsg).
      then((resp) => {
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      });
  }

  render = () => {
    const { highlightFormItems } = this.props;
    const taskData = taskActionData(this.props);

    const invalidDate = this.state.customHold > 30;

    const durationTimes = this.isVHAHold() ? VHA_HOLD_DURATIONS : COLOCATED_HOLD_DURATIONS;

    const holdOptions = durationTimes.map((value) => ({
      label: Number(value) ? `${value} days` : value,
      value
    }));

    const handleError = () => {
      if (this.isVHAHold() && invalidDate) {

        return highlightFormItems ? COPY.VHA_PLACE_CUSTOM_HOLD_INVALID_VALUE : null;
      }

      return highlightFormItems && !this.state.customHold ?
        COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_INVALID_VALUE : null;

    };

    return <QueueFlowModal
      title={TASK_ACTIONS.PLACE_TIMED_HOLD.label}
      button={COPY.MODAL_PUT_TASK_ON_HOLD_BUTTON}
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/appeals/${this.props.appealId}`}
      submitDisabled={this.isVHAHold() && !this.validateForm()}
      validateForm={this.validateForm}
      submitButtonClassNames={['usa-button']}
      submit={this.submit}
    >
      <SearchableDropdown
        name={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
        searchable={false}
        errorMessage={highlightFormItems && !this.state.hold ? 'Choose one' : null}
        placeholder={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
        value={this.state.hold}
        onChange={(option) => option && this.setState({ hold: option.value })}
        options={holdOptions}
        styling={marginBottom(2)}
      />
      {this.state.hold === CUSTOM_HOLD_DURATION_TEXT && <TextField
        name={this.isVHAHold() ?
          COPY.VHA_ACTION_PLACE_CUSTOM_HOLD_COPY :
          COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY
        }
        type="number"
        value={this.state.customHold}
        onChange={(customHold) => this.setState({ customHold })}
        errorMessage={handleError()}
        inputProps={labelTextStyling}
        inputStyling={marginTop(0)} /> }
      <TextareaField
        value={this.state.instructions}
        name="instructions"
        label="Notes"
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.NOTES_ERROR_FIELD_REQUIRED : null}
        onChange={(instructions) => this.setState({ instructions })}
        styling={marginTop(2)} />
    </QueueFlowModal>;
  }
}

StartHoldModal.propTypes = {
  appeal: PropTypes.shape({
    veteranFullName: PropTypes.string
  }),
  appealId: PropTypes.string,
  highlightFormItems: PropTypes.bool,
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    type: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  highlightFormItems: state.ui.highlightFormItems,
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  resetErrorMessages,
  resetSuccessMessages,
  onReceiveAmaTasks
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(StartHoldModal));
