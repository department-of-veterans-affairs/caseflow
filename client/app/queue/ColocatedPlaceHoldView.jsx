import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import classNames from 'classnames';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

import {
  taskById,
  appealWithDetailSelector
} from './selectors';
import { onReceiveAmaTasks } from './QueueActions';
import { requestPatch } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Alert from '../components/Alert';
import TextareaField from '../components/TextareaField';

import {
  fullWidth,
  marginBottom,
  marginTop,
  COLOCATED_HOLD_DURATIONS
} from './constants';

class ColocatedPlaceHoldView extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hold: '',
      customHold: null,
      instructions: ''
    };
  }

  validateForm = () => {
    if (!COLOCATED_HOLD_DURATIONS.includes(this.state.hold) || this.state.instructions === '') {
      return false;
    }
    if (Number(this.state.hold)) {
      return true;
    }
    if (this.state.hold === 'Custom') {
      return Number(this.state.customHold);
    }
  }

  goToNextStep = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          status: 'on_hold',
          on_hold_duration: this.state.customHold || this.state.hold,
          instructions: this.state.instructions
        }
      }
    };
    const successMsg = {
      title: sprintf(
        COPY.COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION,
        appeal.veteranFullName,
        this.state.customHold || this.state.hold
      ),
      detail: COPY.COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION_DETAIL
    };

    this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const {
      task,
      error,
      appeal,
      highlightFormItems
    } = this.props;
    const columnStyling = css({
      width: '50%',
      maxWidth: '25rem'
    });
    const errorClass = classNames({
      'usa-input-error': highlightFormItems && !this.state.hold
    });

    return <React.Fragment>
      <h1 className="cf-push-left" {...css(fullWidth, marginBottom(1))}>
        {sprintf(COPY.COLOCATED_ACTION_PLACE_HOLD_HEAD, appeal.veteranFullName, appeal.veteranFileNumber)}
      </h1>
      <div {...fullWidth}>
        <span {...css(columnStyling, { float: 'left' })}>
          <strong>Veteran ID:</strong> {appeal.veteranFileNumber}
        </span>
        <span {...columnStyling}>
          <strong>Task:</strong> {CO_LOCATED_ADMIN_ACTIONS[task.label]}
        </span>
      </div>
      <hr />
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <h4 {...marginTop(3)}>{COPY.COLOCATED_ACTION_PLACE_HOLD_COPY}</h4>
      <div className={errorClass} {...marginTop(1)}>
        <SearchableDropdown
          name={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
          searchable={false}
          hideLabel
          errorMessage={highlightFormItems && !this.state.hold ? 'Choose one' : null}
          placeholder={COPY.COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL}
          value={this.state.hold}
          onChange={(option) => option && this.setState({ hold: option.value })}
          options={COLOCATED_HOLD_DURATIONS.map((value) => ({
            label: Number(value) ? `${value} days` : value,
            value
          }))} />
      </div>
      {this.state.hold === 'Custom' && <React.Fragment>
        <h4 {...marginTop(3)}>{COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY}</h4>
        <div {...css(marginTop(1), { '& .usa-input-error': marginTop(1) })}>
          <TextField
            name={COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY}
            type="number"
            value={this.state.customHold}
            onChange={(customHold) => this.setState({ customHold })}
            errorMessage={highlightFormItems && !this.state.customHold ?
              COPY.COLOCATED_ACTION_PLACE_CUSTOM_HOLD_INVALID_VALUE : null
            }
            label={false} />
        </div>
      </React.Fragment>}
      <TextareaField
        label="Notes:"
        name="instructions"
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
        value={this.state.instructions}
        onChange={(instructions) => this.setState({ instructions })}
        styling={marginTop(2)} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const {
    highlightFormItems,
    messages: { error }
  } = state.ui;

  return {
    error,
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

const WrappedComponent = decisionViewBase(ColocatedPlaceHoldView, {
  hideCancelButton: true,
  continueBtnText: COPY.COLOCATED_ACTION_PLACE_HOLD_BUTTON_COPY
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
));
