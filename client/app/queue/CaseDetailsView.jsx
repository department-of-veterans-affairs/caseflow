import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Alert from '../components/Alert';
// import IssueAma from '../components/IssueAma';
import AppellantDetail from './AppellantDetail';
import VeteranDetail from './VeteranDetail';
import VeteranCasesView from './VeteranCasesView';
import CaseHearingsDetail from './CaseHearingsDetail';
import PowerOfAttorneyDetail from './PowerOfAttorneyDetail';
import CaseTitle from './CaseTitle';
import CaseTitleDetails from './CaseTitleDetails';
import TaskSnapshot from './TaskSnapshot';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import StickyNavContentArea from './StickyNavContentArea';
import { resetErrorMessages, resetSuccessMessages, setHearingDay } from './uiReducer/uiActions';
import CaseTimeline from './CaseTimeline';
import { getQueryParams } from '../util/QueryParamsUtil';

import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';
import COPY from '../../COPY.json';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  appealWithDetailSelector
} from './selectors';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

const anchorEditLinkStyling = css({
  fontSize: '1.5rem',
  fontWeight: 'normal',
  margin: '5px'
});

const alertPaddingStyle = css({
  marginTop: '2rem'
});

class CaseDetailsView extends React.PureComponent {
  componentDidMount = () => {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);
    this.props.resetErrorMessages();

    const { hearingDate, regionalOffice, hearingTime } = getQueryParams(window.location.search);

    if (hearingDate && regionalOffice) {
      this.props.setHearingDay({
        hearingDate,
        hearingTime: decodeURIComponent(hearingTime),
        regionalOffice
      });
    }
  }

  render = () => {
    const {
      appealId,
      appeal,
      error,
      success
    } = this.props;

    return <React.Fragment>
      {error && <div {...alertPaddingStyle}><Alert title={error.title} type="error">
        {error.detail}
      </Alert></div>}
      {success && <div {...alertPaddingStyle}><Alert type="success" title={success.title} scrollOnAlert={false}>
        {success.detail}
      </Alert></div>}
      <AppSegment filledBackground>
        <CaseTitle appeal={appeal} />
        <CaseTitleDetails appealId={appealId} redirectUrl={window.location.pathname}
          hasCaseDetailsRole={this.props.hasCaseDetailsRole} />
        { this.props.veteranCaseListIsVisible &&
          <VeteranCasesView
            caseflowVeteranId={appeal.caseflowVeteranId}
            veteranId={appeal.veteranFileNumber}
          />
        }
        <TaskSnapshot appealId={appealId} />
        <hr {...horizontalRuleStyling} />
        <StickyNavContentArea>
          <CaseDetailsIssueList
            title="Issues"
            isLegacyAppeal={appeal.isLegacyAppeal}
            additionalHeaderContent={appeal.canEditRequestIssues &&
              <span className="cf-push-right" {...anchorEditLinkStyling}>
                <Link href={`/appeals/${appealId}/edit`}>{COPY.CORRECT_REQUEST_ISSUES_LINK}</Link>
              </span>}
            issues={appeal.issues}
            decisionIssues={appeal.decisionIssues}
          />
          <PowerOfAttorneyDetail title="Power of Attorney" appealId={appealId} />
          {(appeal.hearings.length || appeal.completedHearingOnPreviousAppeal) &&
          <CaseHearingsDetail title="Hearings" appeal={appeal} />}
          <VeteranDetail title="About the Veteran" appeal={appeal} />
          {!_.isNull(appeal.appellantFullName) &&
          <AppellantDetail title="About the Appellant" appeal={appeal} />}
          <CaseTimeline title="Case Timeline" appeal={appeal} />}
        </StickyNavContentArea>
      </AppSegment>
    </React.Fragment>;
  };
}

CaseDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired,
  hasCaseDetailsRole: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  const { success, error } = state.ui.messages;
  const { veteranCaseListIsVisible } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    success,
    error,
    veteranCaseListIsVisible
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    resetErrorMessages,
    resetSuccessMessages,
    setHearingDay
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(CaseDetailsView);
