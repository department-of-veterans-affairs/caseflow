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

import {
  getTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import { setTaskAttrs } from './QueueActions';
import { prepareTasksForStore } from './utils';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import Alert from '../components/Alert';
import TextareaField from '../components/TextareaField';
import { requestSave } from './uiReducer/uiActions';

import {
  fullWidth,
  marginBottom,
  marginTop,
  COLOCATED_HOLD_DURATIONS
} from './constants';

import type { State, UiStateMessage } from './types/state';
import type { Task, Appeal } from './types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  task: Task,
  appeal: Appeal,
  error: ?UiStateMessage,
  highlightFormItems: boolean,
  requestPatch: typeof requestPatch,
  setTaskAttrs: typeof setTaskAttrs
|};

class AdvancedOnDocketMotionView extends React.Component<Props> {
  constructor(props) {
    super(props);

    this.state = {
      granted: null,
      reason: null
    };
  }

  validateForm = () => {
    return this.state.granted !== null && this.state.reason !== null;
  }

  goToNextStep = () => {
    const {
      appeal
    } = this.props;
    const payload = {
      data: {
        advance_on_docket_motions: {
          reason: this.state.reason,
          granted: this.state.granted === "granted"
        }
      }
    };
    const successMsg = {
      title: "Advanced on docket motion",
      detail: "Successful"
    };

    this.props.requestSave(`/appeals/${appeal.externalId}/advance_on_docket_motions`, payload, successMsg);
  }

  render = () => {
    const {
      error,
      appeal,
      highlightFormItems
    } = this.props;

    return <React.Fragment>
      <h1>
        Update Advanced on Docket (AOD) Status
      </h1>
      <hr />
      <h3>AOD Motion Disposition</h3>
      <SearchableDropdown
        name="AOD Motion Disposition"
        searchable={false}
        hideLabel
        errorMessage={highlightFormItems && !this.state.granted ? 'Choose one' : null}
        placeholder="Select grant or deny"
        value={this.state.granted}
        onChange={(option) => option && this.setState({ granted: option.value })}
        options={[
          { label: 'Granted', value: 'granted' },
          { label: 'Denied', value: 'denied' }
        ]} />
      <h3>Reason</h3>
      <SearchableDropdown
        name="Reason"
        searchable={false}
        hideLabel
        errorMessage={highlightFormItems && !this.state.reason ? 'Choose one' : null}
        placeholder="Select a type"
        value={this.state.reason}
        onChange={(option) => option && this.setState({ reason: option.value })}
        options={[
          { label: 'Financial distress', value: 'financial_distress' },
          { label: 'Age', value: 'age' },
          { label: 'Serious illness', value: 'serious_illness' },
          { label: 'Other', value: 'other' }
        ]} />
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
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  setTaskAttrs
}, dispatch);

const WrappedComponent = decisionViewBase(AdvancedOnDocketMotionView, {
  hideCancelButton: true,
  continueBtnText: "Submit"
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
