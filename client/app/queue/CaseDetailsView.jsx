import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Alert from '../components/Alert';
import AppellantDetail from './AppellantDetail';
import VeteranDetail from './VeteranDetail';
import CaseHearingsDetail from './CaseHearingsDetail';
import CaseTitle from './CaseTitle';
import CaseSnapshot from './CaseSnapshot';
import CaseDetailsIssueList from './components/CaseDetailsIssueList';
import StickyNavContentArea from './StickyNavContentArea';
import { CATEGORIES, TASK_ACTIONS } from './constants';
import { COLORS } from '../constants/AppConstants';

import { clearActiveAppealAndTask } from './CaseDetail/CaseDetailActions';

// TODO: Pull this horizontal rule styling out somewhere.
const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '3rem',
  marginBottom: '3rem'
});

const PowerOfAttorneyDetail = ({ poa }) => <p>{poa.representative_type} - {poa.representative_name}</p>;

class CaseDetailsView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
  };

  componentDidMount = () => window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);

  render = () => {
    const {
      appealId,
      appeal,
      task,
      error,
      success
    } = this.props;

    return <AppSegment filledBackground>
      <CaseTitle appeal={appeal} appealId={appealId} redirectUrl={window.location.pathname} />
      {error && <Alert title={error.title} type="error">
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <CaseSnapshot appeal={appeal} task={task} />
      <hr {...horizontalRuleStyling} />
      <StickyNavContentArea>
        <CaseDetailsIssueList
          title="Issues"
          isLegacyAppeal={appeal.attributes.is_legacy_appeal}
          issues={appeal.attributes.issues}
        />
        <PowerOfAttorneyDetail title="Power of Attorney" poa={appeal.attributes.power_of_attorney} />
        {appeal.attributes.hearings.length &&
        <CaseHearingsDetail title="Hearings" appeal={appeal} />}
        <VeteranDetail title="About the Veteran" appeal={appeal} />
        {!_.isNull(appeal.attributes.appellant_full_name) &&
        <AppellantDetail title="About the Appellant" appeal={appeal} />}
      </StickyNavContentArea>
    </AppSegment>;
  };
}

CaseDetailsView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state) => {
  const { activeAppeal, activeTask } = state.caseDetail;
  const { appeals, tasks } = state.queue;
  const { success, error } = state.ui.messages;

  return {
    appeal: activeAppeal ? appeals[activeAppeal.attributes.vacols_id] : activeAppeal,
    task: activeTask ? tasks[activeTask.id] : activeTask,
    success,
    error
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveAppealAndTask
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseDetailsView);
