// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetSaveState,
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch
} from '../uiReducer/uiActions';
import {
  onRegionalOfficeChange,
  onHearingDayChange,
  onHearingTimeChange,
  onHearingLocationChange
} from '../../components/common/actions';
import { fullWidth } from '../constants';
import editModalBase from './EditModalBase';
import { formatDateStringForApi, formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

import type {
  State
} from '../types/state';

import { withRouter } from 'react-router-dom';
import RadioField from '../../components/RadioField';
import {
  HearingDateDropdown,
  RegionalOfficeDropdown,
  VeteranHearingLocationsDropdown
} from '../../components/DataDropdowns';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  appealWithDetailSelector,
  actionableTasksForAppeal
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import { prepareAppealForStore } from '../utils';
import _ from 'lodash';
import type { Appeal, Task } from '../types/models';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING } from '../../hearings/constants/constants';

type Params = {|
  task: Task,
  taskId: string,
  appeal: Appeal,
  appealId: string,
  userId: string
|};

type Props = Params & {|
  // From state
  savePending: boolean,
  selectedRegionalOffice: string,
  scheduleHearingTask: Object,
  openHearing: Object,
  history: Object,
  hearingDay: Object,
  selectedHearingDay: Object,
  selectedHearingTime: string,
  // Action creators
  showErrorMessage: typeof showErrorMessage,
  resetErrorMessages: typeof resetErrorMessages,
  showSuccessMessage: typeof showSuccessMessage,
  resetSuccessMessages: typeof resetSuccessMessages,
  resetSaveState: typeof resetSaveState,
  onRegionalOfficeChange: typeof onRegionalOfficeChange,
  requestPatch: typeof requestPatch,
  onReceiveAmaTasks: typeof onReceiveAmaTasks,
  onHearingDayChange: typeof onHearingDayChange,
  onHearingTimeChange: typeof onHearingTimeChange,
  onReceiveAppealDetails: typeof onReceiveAppealDetails,
  // Inherited from EditModalBase
  setLoading: Function,
|};

type LocalState = {|
  timeOptions: Array<Object>
|}

class AssignHearingModal extends React.PureComponent<Props, LocalState> {

  componentDidMount = () => {
    const { hearingDay, openHearing, appeal } = this.props;

    if (openHearing) {
      this.props.showErrorMessage({
        title: 'Open Hearing',
        detail: `This appeal has an open hearing on ${formatDateStr(openHearing.date)}. ` +
                'You cannot schedule another hearing.'
      });

      return;
    }

    if (appeal.veteranAvailableHearingLocations) {
      const location = appeal.veteranAvailableHearingLocations[0];

      if (location) {
        this.props.onHearingLocationChange({
          name: location.name,
          address: location.address,
          city: location.city,
          state: location.state,
          zipCode: location.zipCode,
          distance: location.distance,
          classification: location.classification,
          facilityId: location.facilityId,
          facilityType: location.facilityType
        });
      }
    }

    if (hearingDay.hearingTime) {
      this.props.onHearingTimeChange(hearingDay.hearingTime);
    }
  }

  submit = () => {
    return this.completeScheduleHearingTask();
  };

  validateForm = () => {

    if (this.props.openHearing) {
      return false;
    }

    const hearingDate = this.formatHearingDate();

    const invalid = [];

    if (!hearingDate) {
      invalid.push('Date of Hearing');
    }
    if (!this.props.selectedHearingTime) {
      invalid.push('Hearing Time');
    }

    if (invalid.length > 0) {

      this.props.showErrorMessage({
        title: 'Required Fields',
        detail: `Please fill in the following fields: ${invalid.join(', ')}.`
      });

      return false;
    }

    return true;
  }

  completeScheduleHearingTask = () => {

    const {
      appeal,
      scheduleHearingTask, history,
      selectedHearingDay, selectedRegionalOffice,
      selectedHearingLocation
    } = this.props;

    const hearingLocation = selectedHearingLocation ||
      appeal.veteranAvailableHearingLocations ? appeal.veteranAvailableHearingLocations[0] : null;

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              regional_office_value: selectedRegionalOffice,
              hearing_pkseq: selectedHearingDay.hearingId,
              hearing_type: this.getHearingType(),
              hearing_date: this.formatHearingDate(),
              hearing_location: ApiUtil.convertToSnakeCase(hearingLocation)
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

  getTimeOptions = () => {
    const { appeal: { sanitizedHearingRequestType } } = this.props;

    if (sanitizedHearingRequestType === 'video') {
      return [
        { displayText: '8:30 am',
          value: '8:30 am ET' },
        { displayText: '12:30 pm',
          value: '12:30 pm ET' }
      ];
    }

    return [
      { displayText: '9:00 am',
        value: '9:00 am ET' },
      { displayText: '1:00 pm',
        value: '1:00 pm ET' }
    ];

  }

  getRO = () => {
    const { appeal, hearingDay } = this.props;
    const { sanitizedHearingRequestType } = appeal;

    if (sanitizedHearingRequestType === 'central_office') {
      return 'C';
    } else if (hearingDay.regionalOffice) {
      return hearingDay.regionalOffice;
    } else if (appeal.regionalOffice) {
      return appeal.regionalOffice.key;
    }

    return '';
  }

  getHearingType = () => {
    const { appeal: { sanitizedHearingRequestType } } = this.props;

    return sanitizedHearingRequestType === 'central_office' ? CENTRAL_OFFICE_HEARING : VIDEO_HEARING;
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

  formatDateString = (dateToFormat) => {
    const formattedDate = formatDateStr(dateToFormat);

    return formatDateStringForApi(formattedDate);
  };

  formatHearingDate = () => {
    const { selectedHearingDay, selectedHearingTime } = this.props;

    if (selectedHearingDay && !selectedHearingTime) {
      return new Date(selectedHearingDay.hearingDate);
    } else if (!selectedHearingTime || !selectedHearingDay) {
      return null;
    }

    const dateParts = selectedHearingDay.hearingDate.split('-');
    const year = parseInt(dateParts[0], 10);
    const month = parseInt(dateParts[1], 10) - 1;
    const day = parseInt(dateParts[2], 10);
    const timeParts = selectedHearingTime.split(':');
    let hour = parseInt(timeParts[0], 10);

    if (hour === 1) {
      hour += 12;
    }
    const minute = parseInt(timeParts[1].split(' ')[0], 10);
    const hearingDate = new Date(year, month, day, hour, minute);

    return hearingDate;
  };

  getInitialValues = () => {
    const { hearingDay } = this.props;

    return {
      hearingTime: hearingDay.hearingTime,
      hearingDate: hearingDay.hearingDate,
      regionalOffice: this.getRO()
    };
  }

  render = () => {
    const {
      selectedHearingDay, selectedRegionalOffice, appeal,
      selectedHearingTime, openHearing, selectedHearingLocation
    } = this.props;

    const initVals = this.getInitialValues();
    const timeOptions = this.getTimeOptions();
    const currentRegionalOffice = selectedRegionalOffice || initVals.regionalOffice;
    const { address_line_1, city, state, zip } = appeal.appellantAddress || {};

    if (openHearing) {
      return null;
    }

    /* eslint-disable camelcase */
    return <React.Fragment>
      <div {...fullWidth} {...css({ marginBottom: '0' })} >
        <p>
          Veteran Address<br />
          {address_line_1}<br />
          {`${city}, ${state} ${zip}`}
        </p>
        <RegionalOfficeDropdown
          onChange={this.props.onRegionalOfficeChange}
          readOnly
          value={selectedRegionalOffice || initVals.regionalOffice}
          validateValueOnMount />

        {selectedRegionalOffice && <VeteranHearingLocationsDropdown
          label="Suggested Hearing Location"
          key={`ahl-dropdown__${currentRegionalOffice}`}
          regionalOffice={currentRegionalOffice}
          veteranFileNumber={appeal.veteranFileNumber}
          dynamic={false}
          staticHearingLocations={appeal.veteranAvailableHearingLocations}
          onChange={this.props.onHearingLocationChange}
          value={selectedHearingLocation}
        />}

        {selectedRegionalOffice && <HearingDateDropdown
          key={selectedRegionalOffice}
          regionalOffice={selectedRegionalOffice}
          onChange={this.props.onHearingDayChange}
          value={selectedHearingDay || initVals.hearingDate}
          validateValueOnMount
        />}

        <RadioField
          name="time"
          label="Time"
          strongLabel
          options={timeOptions}
          onChange={this.props.onHearingTimeChange}
          value={selectedHearingTime || initVals.hearingTime} />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  scheduleHearingTask: _.find(
    actionableTasksForAppeal(state, { appealId: ownProps.appealId }),
    (task) => task.type === 'ScheduleHearingTask' && task.status !== 'completed'
  ),
  openHearing: _.find(
    appealWithDetailSelector(state, ownProps).hearings,
    (hearing) => hearing.disposition === null
  ),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOfficeOptions: state.components.regionalOffices,
  hearingDay: state.ui.hearingDay,
  selectedHearingDay: state.components.selectedHearingDay,
  selectedHearingTime: state.components.selectedHearingTime,
  selectedHearingLocation: state.components.selectedHearingLocation
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestPatch,
  onReceiveAmaTasks,
  onRegionalOfficeChange,
  onHearingDayChange,
  onHearingTimeChange,
  onHearingLocationChange,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    AssignHearingModal, { title: 'Schedule Veteran',
      button: 'Schedule' }
  ))
): React.ComponentType<Params>);
