// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector
} from './selectors';
import { setAppealAod } from './QueueActions';

import decisionViewBase from './components/DecisionViewBase';
import SearchableDropdown from '../components/SearchableDropdown';
import Alert from '../components/Alert';
import { requestSave } from './uiReducer/uiActions';

import type { State, UiStateMessage } from './types/state';
import type { Appeal } from './types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  appeal: Appeal,
  error: ?UiStateMessage,
  highlightFormItems: boolean,
  requestSave: typeof requestSave,
  setAppealAod: typeof setAppealAod
|};

type ViewState = {|
  granted: ?string,
  reason: ?string
|};

const GRANTED = 'granted';

class AdvancedOnDocketMotionView extends React.Component<Props, ViewState> {
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
          granted: this.state.granted === GRANTED
        }
      }
    };
    const successMsg = {
      title: 'Advanced on docket motion',
      detail: 'Successful'
    };

    this.props.requestSave(`/appeals/${appeal.externalId}/advance_on_docket_motions`, payload, successMsg).
      then(() => {
        if (this.state.granted === GRANTED) {
          this.props.setAppealAod(appeal.externalId);
        }
      });

  }

  render = () => {
    const {
      error,
      highlightFormItems
    } = this.props;

    return <React.Fragment>
      <h1>
        {COPY.ADVANCE_ON_DOCKET_MOTION_PAGE_TITLE}
      </h1>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <hr />
      <h3>{COPY.ADVANCE_ON_DOCKET_MOTION_DISPOSITION_DROPDOWN}</h3>
      <SearchableDropdown
        name="AOD Motion Disposition"
        searchable={false}
        hideLabel
        errorMessage={highlightFormItems && !this.state.granted ? 'Choose one' : null}
        placeholder={COPY.ADVANCE_ON_DOCKET_MOTION_DISPOSITION_DROPDOWN_PLACEHOLDER}
        value={this.state.granted}
        onChange={(option) => option && this.setState({ granted: option.value })}
        options={[
          { label: 'Granted',
            value: GRANTED },
          { label: 'Denied',
            value: 'denied' }
        ]} />
      <h3>{COPY.ADVANCE_ON_DOCKET_MOTION_REASON_DROPDOWN}</h3>
      <SearchableDropdown
        name="Reason"
        searchable={false}
        hideLabel
        errorMessage={highlightFormItems && !this.state.reason ? 'Choose one' : null}
        placeholder={COPY.ADVANCE_ON_DOCKET_MOTION_REASON_DROPDOWN_PLACEHOLDER}
        value={this.state.reason}
        onChange={(option) => option && this.setState({ reason: option.value })}
        options={[
          { label: 'Financial distress',
            value: 'financial_distress' },
          { label: 'Age',
            value: 'age' },
          { label: 'Serious illness',
            value: 'serious_illness' },
          { label: 'Other',
            value: 'other' }
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
  setAppealAod
}, dispatch);

const WrappedComponent = decisionViewBase(AdvancedOnDocketMotionView, {
  hideCancelButton: true,
  continueBtnText: 'Submit'
});

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(WrappedComponent)
): React.ComponentType<Params>);
