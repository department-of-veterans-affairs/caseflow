// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import COPY from '../../COPY.json';

import {
  appealWithDetailSelector
} from './selectors';
import { setAppealAod } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import editModalBase from './components/EditModalBase';
import { requestSave } from './uiReducer/uiActions';

import type { State } from './types/state';
import type { Appeal } from './types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  appeal: Appeal,
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

  submit = () => {
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
      title: 'AOD status updated'
    };

    return this.props.requestSave(`/appeals/${appeal.externalId}/advance_on_docket_motions`, payload, successMsg).
      then(() => {
        if (this.state.granted === GRANTED) {
          this.props.setAppealAod(appeal.externalId);
        }
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  render = () => {
    const {
      highlightFormItems
    } = this.props;

    return <React.Fragment>
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
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  setAppealAod
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(AdvancedOnDocketMotionView, { title: COPY.ADVANCE_ON_DOCKET_MOTION_PAGE_TITLE })
): React.ComponentType<Params>);
