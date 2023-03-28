import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useState } from 'react';
import { supportsSubstitutionPreDispatch } from './substituteAppellant/caseDetails/utils';
import { useHistory } from 'react-router';
import { appealWithDetailSelector } from './selectors';
import Button from '../components/Button';
import CaseTitle from './CaseTitle';
import COPY from 'app/../COPY';
import { css } from 'glamor';
import {
  stopPollingHearing,
  transitionAlert,
  clearAlerts,
} from '../components/common/actions';
import {
  resetErrorMessages,
  resetSuccessMessages,
  setHearingDay,
} from './uiReducer/uiActions';
import CaseTitleDetails from './CaseTitleDetails';
import Alert from '../components/Alert';
import ApiUtil from '../util/ApiUtil';

const sectionGap = css({ marginTop: '3.5rem' });

import NotificationTable from './components/NotificationTable';

export const NotificationsView = (props) => {
  const [modalState, setModalState] = useState(false);
  const openModal = () => {
    setModalState(true);
  };
  const closeModal = () => {
    setModalState(false);
  };

  const [alert, setAlert] = useState([{
    alertState: false,
    alertMessage: ''
  }]);
  const [loading, setLoading] = useState(false);

  const { push } = useHistory();
  const { appealId, featureToggles } = props;
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const currentUserOnClerkOfTheBoard = useSelector((state) =>
    state.ui.organizations.some((organization) =>
      ['Clerk of the Board'].includes(organization.name)
    )
  );
  const userIsCobAdmin = useSelector(
    (state) => state.ui.userIsCobAdmin
  );
  const supportPendingAppealSubstitution = supportsSubstitutionPreDispatch({
    appeal,
    currentUserOnClerkOfTheBoard,
    featureToggles,
    userIsCobAdmin
  });

  const alertStyle = css({
    marginBottom: '30px',
    marginTop: '0px'
  });

  const errorCode = 'Error Code: ';
  const pdfURL = `/appeals/${appealId}/notifications.pdf`;
  let errorUuid = '';

  //  Error handling to add alert message for PDF generation
  const generatePDF = () => {
    setLoading(true);
    const status = ApiUtil.get(pdfURL).then(() => {
      window.location.href = pdfURL;
      setLoading(false);
    }).
      catch((error) => {

        if (error.status > 299 || error.status < 200) {
          errorUuid = JSON.parse(error.response.text).errors[0].message;
          setAlert({ alertState: true, alertMessage: errorUuid });
        }
        setLoading(false);
      });

    return status;
  };

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <CaseTitle titleHeader = {`Case notifications for ${appeal.veteranFullName}`} appeal={appeal} hideCaseView />
        {alert.alertState && <Alert type="error" title={COPY.PDF_GENERATION_ERROR_TITLE} styling={alertStyle}
        >{COPY.PDF_GENERATION_ERROR_MESSAGE}<br />{errorCode}{alert.alertMessage}</Alert>}
        {supportPendingAppealSubstitution && (
          <div {...sectionGap}>
            <Button
              onClick={() =>
                push(`/queue/appeals/${appealId}/substitute_appellant`)
              }
            >
              {COPY.SUBSTITUTE_APPELLANT_BUTTON}
            </Button>
          </div>
        )}
        <CaseTitleDetails
          appealId={appealId}
          redirectUrl={window.location.pathname}
          hideOTSection
          userCanAccessReader={props.userCanAccessReader}
          hideDocs
          hideDecisionDocument
          showEfolderLink
        />
        <div {...sectionGap} >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <p className="notification-text">
              VA Notify sent these status notifications to the Appellant about their case.
            </p>
            <Button id = "download-button" classNames={['usa-button-secondary']} onClick={() =>
              generatePDF()} loading={loading} >Download</Button>
          </div>

          <div className="notification-table">
            <NotificationTable
              appealId={appealId}
              modalState={modalState}
              openModal={openModal}
              closeModal={closeModal}
            />
          </div>
        </div>
      </AppSegment>

    </React.Fragment>
  );

};

NotificationsView.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string.isRequired,
  clearAlerts: PropTypes.func,
  tasks: PropTypes.array,
  error: PropTypes.object,
  featureToggles: PropTypes.object,
  resetErrorMessages: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  setHearingDay: PropTypes.func,
  success: PropTypes.object,
  userCanAccessReader: PropTypes.bool,
  veteranCaseListIsVisible: PropTypes.bool,
  userCanScheduleVirtualHearings: PropTypes.bool,
  userCanEditUnrecognizedPOA: PropTypes.bool,
  scheduledHearingId: PropTypes.string,
  pollHearing: PropTypes.bool,
  stopPollingHearing: PropTypes.func,
  substituteAppellant: PropTypes.object,
  vsoVirtualOptIn: PropTypes.bool,
  hideOTSection: PropTypes.bool,
  showEfolderLink: PropTypes.bool
};

NotificationsView.defaultProps = {
  hideOTSection: true,
  showEfolderLink: true
};

const mapStateToProps = (state) => ({
  scheduledHearingId: state.components.scheduledHearing.externalId,
  pollHearing: state.components.scheduledHearing.polling,
  featureToggles: state.ui.featureToggles,
  substituteAppellant: state.substituteAppellant,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      clearAlerts,
      resetErrorMessages,
      resetSuccessMessages,
      transitionAlert,
      stopPollingHearing,
      setHearingDay
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(NotificationsView);

