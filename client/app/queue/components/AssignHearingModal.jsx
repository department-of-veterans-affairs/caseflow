import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch
} from '../uiReducer/uiActions';
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
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants/constants';
import QueueFlowModal from './QueueFlowModal';
import AssignHearingForm from '../../hearingSchedule/components/modalForms/AssignHearingForm';

class AssignHearingModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showErrorMessages: false
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

    const {
      appeal, scheduleHearingTask, history, assignHearingForm
    } = this.props;

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              ...assignHearingForm.apiFormattedValues
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
    const { appeal, selectedHearingDay, selectedRegionalOffice } = this.props;

    const hearingDateStr = formatDateStr(selectedHearingDay.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
    const title = `You have successfully assigned ${appeal.veteranFullName} ` +
                  `to a ${this.getHearingType()} hearing on ${hearingDateStr}.`;
    const href = `/hearings/schedule/assign?roValue=${selectedRegionalOffice}`;

    const detail = (
      <p>
        To assign another veteran please use the "Schedule Veterans" link below.
        You can also use the hearings section below to view the hearing in new tab.<br /><br />
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

  render = () => {
    const {
      appeal, openHearing
    } = this.props;

    const { address_line_1, city, state, zip } = appeal.appellantAddress || {};

    if (openHearing) {
      return null;
    }

    /* eslint-disable camelcase */
    return <QueueFlowModal
      submit={this.submit}
      validateForm={this.validateForm}
      title="Schedule Veteran"
      button="Schedule"
    >
      <div {...fullWidth}>
        <p>
          Veteran Address<br />
          {address_line_1}<br />
          {`${city}, ${state} ${zip}`}
        </p>
        <AssignHearingForm
          appeal={appeal}
          showErrorMessages={this.state.showErrorMessages}
          {...this.getInitialValues()} />
      </div>
    </QueueFlowModal>;
  }
}

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
