import React, { useContext, useState, useEffect } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants';
import {
  appealWithDetailSelector,
  scheduleHearingTasksForAppeal
} from '../selectors';
import { formatDateStr } from '../../util/DateUtil';
import { fullWidth } from '../constants';
import { onReceiveAppealDetails } from '../QueueActions';
import { prepareAppealForStore } from '../utils';
import {
  showErrorMessage,
  requestPatch
} from '../uiReducer/uiActions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import AssignHearingForm from '../../hearings/components/modalForms/AssignHearingForm';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import { HearingsFormContext } from '../../hearings/contexts/HearingsFormContext';

const AssignHearingModal = (props) => {
  const [showErrorMessages, setShowErrorMessages] = useState(false);
  const [showFullHearingDayWarning, setShowFullHearingDayWarning] = useState(false);

  const hearingsFormContext = useContext(HearingsFormContext);
  const assignHearingForm = hearingsFormContext.state.hearingForms?.assignHearingForm || {};

  const {
    openHearing, hearingDay, appeal, scheduleHearingTask, history, selectedRegionalOffice
  } = props;

  const { address_line_1: addressLine1, city, state, zip } = appeal.appellantAddress || {};

  if (openHearing) {
    return null;
  }

  const toggleFullHearingDayWarning = () => {
    const selectedHearingDay = assignHearingForm.hearingDay || hearingDay;

    if (!selectedHearingDay) {
      return;
    }

    setShowFullHearingDayWarning(selectedHearingDay.filledSlots >= selectedHearingDay.totalSlots);
  };

  useEffect(() => {
    if (openHearing) {
      props.showErrorMessage({
        title: 'Open Hearing',
        detail: `This appeal has an open hearing on ${formatDateStr(openHearing.date)}. ` +
                'You cannot schedule another hearing.'
      });
    }
    toggleFullHearingDayWarning();
  }, [assignHearingForm]);

  const resetAppealDetails = () => {
    ApiUtil.get(`/appeals/${appeal.externalId}`).then((response) => {
      props.onReceiveAppealDetails(prepareAppealForStore([response.body.appeal]));
    });
  };

  const getHearingType = () => selectedRegionalOffice === 'C' ? CENTRAL_OFFICE_HEARING : VIDEO_HEARING;

  const getSuccessMsg = () => {
    const hearingDateStr = formatDateStr(assignHearingForm.hearingDay.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = sprintf(
      COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_TITLE,
      appeal.veteranFullName,
      getHearingType(),
      hearingDateStr
    );
    const href = `/hearings/schedule/assign?regional_office_key=${assignHearingForm.hearingDay.regionalOffice}`;

    const detail = (
      <p>
        {COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL}<br /><br />
        <Link href={href}>Back to Schedule Veterans</Link>
      </p>
    );

    return { title,
      detail };
  };

  const completeScheduleHearingTask = () => {
    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              ...assignHearingForm.apiFormattedValues,
              override_full_hearing_day_validation: showFullHearingDayWarning
            }
          }
        }
      }
    };

    return props.requestPatch(`/tasks/${scheduleHearingTask.taskId}`, payload, getSuccessMsg()).
      then(() => {
        history.goBack();
        resetAppealDetails();

      }, () => {
        if (appeal.isLegacyAppeal) {
          props.showErrorMessage({
            title: 'No Available Slots',
            detail: 'Could not find any available slots for this regional office and hearing day combination. ' +
                    'Please select a different date.'
          });
        } else {
          props.showErrorMessage({
            title: 'No Hearing Day',
            detail: 'Until April 1st hearing days for AMA appeals need to be created manually. ' +
                    'Please contact the Caseflow Team for assistance.'
          });
        }
      });
  };

  const submit = () => completeScheduleHearingTask();

  const getRO = () => {
    if (hearingDay.regionalOffice) {
      return hearingDay.regionalOffice;
    } else if (appeal.regionalOffice) {
      return appeal.regionalOffice.key;
    }

    return '';
  };

  const getInitialValues = () => {
    return {
      initialHearingDate: hearingDay.hearingDate,
      initialRegionalOffice: getRO()
    };
  };

  const validateForm = () => {
    if (openHearing) {
      return false;
    }

    const { errorMessages: { hasErrorMessages } } = assignHearingForm;

    setShowErrorMessages(hasErrorMessages);

    return !hasErrorMessages;
  };

  return (
    <QueueFlowModal
      submit={submit}
      validateForm={validateForm}
      title="Schedule Veteran"
      button="Schedule"
    >
      <div {...fullWidth}>
        {
          showFullHearingDayWarning &&
          <Alert
            title={COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE}
            type="warning"
          >
            {COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL}
          </Alert>
        }
        <p>
          Veteran Address<br />
          {addressLine1}<br />
          {`${city}, ${state} ${zip}`}
        </p>
        <AssignHearingForm
          appeal={appeal}
          showErrorMessages={showErrorMessages}
          {...getInitialValues()} />
      </div>
    </QueueFlowModal>
  );
};

AssignHearingModal.propTypes = {
  openHearing: PropTypes.shape({
    date: PropTypes.string
  }),
  appeal: PropTypes.shape({
    appellantAddress: PropTypes.object,
    externalId: PropTypes.string,
    isLegacyAppeal: PropTypes.bool,
    regionalOffice: PropTypes.object,
    veteranFullName: PropTypes.string
  }),
  hearingDay: PropTypes.shape({
    hearingDate: PropTypes.string,
    regionalOffice: PropTypes.string
  }),
  scheduleHearingTask: PropTypes.shape({
    taskId: PropTypes.string
  }),
  history: PropTypes.object,
  onReceiveAppealDetails: PropTypes.func,
  requestPatch: PropTypes.func,
  showErrorMessage: PropTypes.func,
  selectedRegionalOffice: PropTypes.string
};

const mapStateToProps = (state, ownProps) => ({
  scheduleHearingTask: scheduleHearingTasksForAppeal(state, { appealId: ownProps.appealId })[0],
  openHearing: _.find(
    appealWithDetailSelector(state, ownProps).hearings,
    (hearing) => hearing.disposition === null
  ),
  appeal: appealWithDetailSelector(state, ownProps),
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  hearingDay: state.ui.hearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  requestPatch,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignHearingModal)));
