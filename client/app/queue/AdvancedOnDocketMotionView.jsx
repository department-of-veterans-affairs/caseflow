import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import sprintf from 'sprintf-js';

import COPY from '../../COPY';
import AOD_REASONS from '../../constants/AOD_REASONS';

import {
  appealWithDetailSelector
} from './selectors';
import { setAppealAod } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import { requestSave, showErrorMessage } from './uiReducer/uiActions';
import QueueFlowModal from './components/QueueFlowModal';
import StringUtil from '../util/StringUtil';

class AdvancedOnDocketMotionView extends React.Component {
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
    const {
      reason,
      granted
    } = this.state;

    const payload = {
      data: {
        advance_on_docket_motions: {
          reason,
          granted
        }
      }
    };
    const successMsg = {
      title: sprintf(COPY.ADVANCE_ON_DOCKET_MOTION_SUCCESS_MESSAGE,
        granted ? 'granted' : 'denied', StringUtil.snakeCaseToSentence(reason))
    };

    return this.props.requestSave(`/appeals/${appeal.externalId}/advance_on_docket_motions`, payload, successMsg).
      then(() => this.props.setAppealAod(appeal.externalId, granted)).
      catch(() => {
        // handle the error from the frontend
      });
  }

  render = () => {
    const {
      highlightFormItems,
      appeal
    } = this.props;

    return <QueueFlowModal
      title={COPY.ADVANCE_ON_DOCKET_MOTION_PAGE_TITLE}
      submit={this.submit}
      validateForm={this.validateForm}
      pathAfterSubmit={`/queue/appeals/${appeal.externalId}`}
    >
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
            value: true },
          { label: 'Denied',
            value: false }
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
        options={Object.keys(AOD_REASONS).map((reason) => (
          {
            label: StringUtil.snakeCaseToSentence(reason),
            value: reason
          }))} />
    </QueueFlowModal>;
  }
}

AdvancedOnDocketMotionView.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string
  }),
  requestSave: PropTypes.func,
  setAppealAod: PropTypes.func,
  highlightFormItems: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
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
  showErrorMessage,
  setAppealAod
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(AdvancedOnDocketMotionView));
