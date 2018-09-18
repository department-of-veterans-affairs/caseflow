import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import VeteranDetail from './VeteranDetail';
import VeteranCasesView from './VeteranCasesView';
import CaseHearingsDetail from './CaseHearingsDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import StickyNavContentArea from './StickyNavContentArea';
import SendToLocationModal from './components/SendToLocationModal';

import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';

import {
  appealWithDetailSelector,
  getActiveModalType
} from './selectors';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

const PowerOfAttorneyDetail = ({ poa }) => <p>{poa.representative_type} - {poa.representative_name}</p>;

class CaseDetailsView extends React.PureComponent {
  componentDidMount = () => window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);

  render = () => {
    const {
      appealId,
      appeal,
      error,
      success,
      modal
    } = this.props;

    return <AppSegment filledBackground>
      {modal && <SendToLocationModal appealId={appealId} />}
      <CaseTitle appeal={appeal} appealId={appealId} redirectUrl={window.location.pathname} />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title} scrollOnAlert={false}>
        {success.detail}
      </Alert>}
      { this.props.veteranCaseListIsVisible &&
        <VeteranCasesView
          caseflowVeteranId={appeal.caseflowVeteranId}
          veteranId={appeal.veteranFileNumber}
        />
      }
      <CaseSnapshot appealId={appealId} />
      <hr {...horizontalRuleStyling} />
      <StickyNavContentArea>
        <CaseDetailsIssueList
          title="Issues"
          isLegacyAppeal={appeal.isLegacyAppeal}
          issues={appeal.issues}
        />
        <PowerOfAttorneyDetail title="Power of Attorney" poa={appeal.powerOfAttorney} />
        {appeal.hearings.length &&
        <CaseHearingsDetail title="Hearings" appeal={appeal} />}
        <VeteranDetail title="About the Veteran" appeal={appeal} />
        {!_.isNull(appeal.appellantFullName) &&
        <AppellantDetail title="About the Appellant" appeal={appeal} />}
      </StickyNavContentArea>
    </AppSegment>;
  };
}

CaseDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => {
  const { success, error } = state.ui.messages;
  const { veteranCaseListIsVisible, modals } = state.ui;
  const modalType = getActiveModalType(state);

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    success,
    error,
    veteranCaseListIsVisible,
    modal: modals[modalType],
    modalType
  };
};

export default connect(mapStateToProps)(CaseDetailsView);
