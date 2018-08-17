// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import classNames from 'classnames';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import CO_LOCATED_HOLD_DURATIONS from '../../constants/CO_LOCATED_HOLD_DURATIONS.json';

import {
  getTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Alert from '../components/Alert';

import {
  fullWidth,
  marginBottom,
  marginTop
} from './constants';

import type { State, UiStateMessage } from './types/state';
import type { Task, Appeal } from './types/models';

type ViewState = {|
  hold: string,
  customHold: ?number
|};

type Params = {|
  appealId: string
|};

type Props = Params & {|
  task: Task,
  appeal: Appeal,
  error: ?UiStateMessage,
  highlightFormItems: boolean,
  requestSave: typeof requestSave
|};

class ColocatedPlaceHoldView extends React.Component<Props, ViewState> {
  constructor(props) {
    super(props);

    this.state = {
      hold: '',
      customHold: null
    };
  }

  validateForm = () => {
    if (!CO_LOCATED_HOLD_DURATIONS.includes(this.state.hold)) {
      return false;
    }
    if (Number(this.state.hold)) {
      return true;
    }

    if (this.state.hold === 'Custom') {
      return Number(this.state.customHold);
    }
  }

  // todo: make this a default (method) in decisionViewBase?
  getPrevStepUrl = () => `/queue/appeals/${this.props.appealId}`;

  goToNextStep = () => {
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      data: {
        task: {
          status: 'on_hold',
          on_hold_duration: this.state.customHold || this.state.hold
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

    this.props.requestSave(`/tasks/${task.taskId}`, payload, successMsg, 'patch');
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
          <strong>Task:</strong> {CO_LOCATED_ADMIN_ACTIONS[task.action]}
        </span>
      </div>
      <hr />
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <h4 {...marginTop(3)}>{COPY.COLOCATED_ACTION_PLACE_HOLD_COPY}</h4>
      <div className={errorClass} {...marginTop(1)}>
        <SearchableDropdown
          name="Select number of days"
          hideLabel
          errorMessage={highlightFormItems && !this.state.hold ? 'Choose one' : null}
          placeholder="Select number of days"
          value={this.state.hold}
          onChange={({ value }) => this.setState({ hold: value })}
          options={CO_LOCATED_HOLD_DURATIONS.map((value) => ({
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
            onChange={(value) => this.setState({ customHold: value })}
            errorMessage={highlightFormItems && !this.state.customHold ? 'Please enter a number greater than 0' : null}
            label={false} />
        </div>
      </React.Fragment>}
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const {
    highlightFormItems,
    messages: { error }
  } = state.ui;

  return {
    error,
    highlightFormItems,
    task: getTasksForAppeal(state, ownProps)[0],
    appeal: appealWithDetailSelector(state, ownProps)
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave
}, dispatch);

const WrappedComponent = decisionViewBase(ColocatedPlaceHoldView, {
  hideCancelButton: true,
  continueBtnText: 'Place case on hold'
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
