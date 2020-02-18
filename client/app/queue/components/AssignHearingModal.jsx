import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch
} from '../uiReducer/uiActions';
import COPY from '../../../COPY';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants';
import { fullWidth } from '../constants';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  appealWithDetailSelector,
  scheduleHearingTasksForAppeal
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import { prepareAppealForStore } from '../utils';
import _ from 'lodash';
import QueueFlowModal from './QueueFlowModal';
import Alert from '../../components/Alert';
import AssignHearingForm from '../../hearings/components/modalForms/AssignHearingForm';

class AssignHearingModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showErrorMessages: false,
      showFullHearingDayWarning: false
    };
  }

  componentDidMount = () => {
    const { openHearing } = this.props;

    if (openHearing) {
      this.props.showErrorMessage({
        title: 'Open Hearing',
        detail: `This appeal has an open hearing on ${formatDateStr(openHearing.date)}. ` +
                'You cannot schedule another hearing.'
      });
    }

    this.toggleFullHearingDayWarning();
  }

  componentDidUpdate = () => {
    this.toggleFullHearingDayWarning();
  }

  toggleFullHearingDayWarning = () => {
    const { assignHearingForm, hearingDay } = this.props;
    const selectedHearingDay = (assignHearingForm || {}).hearingDay || hearingDay;

    if (!selectedHearingDay) {
      return;
    }

    this.setState({
      showFullHearingDayWarning: selectedHearingDay.filledSlots >= selectedHearingDay.totalSlots
    });
  }

  submit = () => {
    return this.completeScheduleHearingTask();
  };

  validateForm = () => {
    const { assignHearingForm, openHearing } = this.props;

    if (openHearing) {
      return false;
    }

    const { errorMessages: { hasErrorMessages } } = assignHearingForm;

    this.setState({ showErrorMessages: hasErrorMessages });

    return !hasErrorMessages;
  };

  completeScheduleHearingTask = () => {
    const { appeal, scheduleHearingTask, history, assignHearingForm } = this.props;
    const { showFullHearingDayWarning } = this.state;

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

    return this.props.requestPatch(`/tasks/${scheduleHearingTask.taskId}`, payload, this.getSuccessMsg()).
      then(() => {
        history.goBack();
        this.resetAppealDetails();

      }, () => {
        if (appeal.isLegacyAppeal) {
          this.props.showErrorMessage({
            title: 'No Available Slots',
            detail: 'Could not find any available slots for this regional office and hearing day combination. ' +
                    'Please select a different date.'
          });
        } else {
          this.props.showErrorMessage({
            title: 'No Hearing Day',
            detail: 'Until April 1st hearing days for AMA appeals need to be created manually. ' +
                    'Please contact the Caseflow Team for assistance.'
          });
        }
      });
  }

  resetAppealDetails = () => {
    const { appeal } = this.props;

    ApiUtil.get(`/appeals/${appeal.externalId}`).then((response) => {
      this.props.onReceiveAppealDetails(prepareAppealForStore([response.body.appeal]));
    });
  }

  getRO = () => {
    const { appeal, hearingDay } = this.props;

    if (hearingDay.regionalOffice) {
      return hearingDay.regionalOffice;
    } else if (appeal.regionalOffice) {
      return appeal.regionalOffice.key;
    }

    return '';
  }

  getHearingType = () => {
    const { selectedRegionalOffice } = this.props;

    return selectedRegionalOffice === 'C' ? CENTRAL_OFFICE_HEARING : VIDEO_HEARING;
  }

  getSuccessMsg = () => {
    const { appeal, assignHearingForm } = this.props;

    const hearingDateStr = formatDateStr(assignHearingForm.hearingDay.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = sprintf(
      COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_TITLE,
      appeal.veteranFullName,
      this.getHearingType(),
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
  }

  getInitialValues = () => {
    const { hearingDay } = this.props;

    return {
      initialHearingDate: hearingDay.hearingDate,
      initialRegionalOffice: this.getRO()
    };
  };

  /* eslint-disable camelcase */
  render = () => {
    const { appeal, openHearing } = this.props;
    const { showErrorMessages, showFullHearingDayWarning } = this.state;
    const { address_line_1, city, state, zip } = appeal.appellantAddress || {};

    if (openHearing) {
      return null;
    }

    return (
      <QueueFlowModal
        submit={this.submit}
        validateForm={this.validateForm}
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
            {address_line_1}<br />
            {`${city}, ${state} ${zip}`}
          </p>
          <AssignHearingForm
            appeal={appeal}
            showErrorMessages={showErrorMessages}
            {...this.getInitialValues()} />
        </div>
      </QueueFlowModal>
    );
  }
}

AssignHearingModal.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    appellantAddress: PropTypes.string,
    regionalOffice: PropTypes.shape({
      key: PropTypes.string
    }),
    isLegacyAppeal: PropTypes.bool,
    veteranFullName: PropTypes.string
  }),
  hearingDay: PropTypes.shape({
    regionalOffice: PropTypes.string,
    hearingDate: PropTypes.string
  }),
  openHearing: PropTypes.object,
  selectedRegionalOffice: PropTypes.string,
  showErrorMessage: PropTypes.func,
  assignHearingForm: PropTypes.shape({
    apiFormattedValues: PropTypes.shape({
      with_admin_action_klass: PropTypes.bool,
      admin_action_instructions: PropTypes.string
    }),
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool
    }),
    hearingDay: PropTypes.shape({
      regionalOffice: PropTypes.string,
      hearingDate: PropTypes.string
    })
  }),
  history: PropTypes.shape({
    goBack: PropTypes.func
  }),
  scheduleHearingTask: PropTypes.object,
  requestPatch: PropTypes.func,
  onReceiveAppealDetails: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  scheduleHearingTask: scheduleHearingTasksForAppeal(state, { appealId: ownProps.appealId })[0],
  openHearing: _.find(
    appealWithDetailSelector(state, ownProps).hearings,
    (hearing) => hearing.disposition === null
  ),
  assignHearingForm: state.components.forms.assignHearing,
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOfficeOptions: state.components.regionalOffices,
  hearingDay: state.ui.hearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch,
  onReceiveAmaTasks,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignHearingModal)));
