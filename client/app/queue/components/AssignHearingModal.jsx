import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
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
  onHearingLocationChange,
  onHearingOptionalTime
} from '../../components/common/actions';
import { fullWidth } from '../constants';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

import { withRouter } from 'react-router-dom';
import RadioField from '../../components/RadioField';
import {
  HearingDateDropdown,
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown
} from '../../components/DataDropdowns';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  appealWithDetailSelector,
  scheduleHearingTasksForAppeal
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import { prepareAppealForStore } from '../utils';
import _ from 'lodash';
import { CENTRAL_OFFICE_HEARING, VIDEO_HEARING, TIME_OPTIONS } from '../../hearings/constants/constants';
import SearchableDropdown from '../../components/SearchableDropdown';
import moment from 'moment';
import QueueFlowModal from './QueueFlowModal';

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

class AssignHearingModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      invalid: {
        time: null,
        day: null,
        regionalOffice: null,
        location: null
      }
    };
  }

  componentDidMount = () => {
    const { openHearing, appeal } = this.props;

    if (openHearing) {
      this.props.showErrorMessage({
        title: 'Open Hearing',
        detail: `This appeal has an open hearing on ${formatDateStr(openHearing.date)}. ` +
                'You cannot schedule another hearing.'
      });

      return;
    }

    if (appeal.availableHearingLocations) {
      const sortedLocations = _.orderBy(appeal.availableHearingLocations, ['distance'], ['asc']);
      const location = sortedLocations[0];

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
  }

  submit = () => {
    return this.completeScheduleHearingTask();
  };

  onHearingOptionalTime = (option) => {
    this.props.onHearingOptionalTime(option.value);
  };

  validateForm = () => {
    const {
      selectedHearingDay,
      selectedRegionalOffice,
      selectedHearingTime,
      selectedOptionalTime
      // selectedHearingLocation
    } = this.props;

    const validTime = (selectedHearingTime === 'other' && selectedOptionalTime) ||
      (selectedHearingTime !== 'other' && Boolean(selectedHearingTime));

    const invalid = {
      day: selectedHearingDay && selectedHearingDay.hearingId ? null : 'Please select a hearing day',
      regionalOffice: selectedRegionalOffice ? null : 'Please select a regional office',
      time: validTime ? null : 'Please pick a hearing time'
      // location: selectedHearingLocation ? null : 'Please select a hearing location'
    };

    this.setState({ invalid });

    const invalidVals = _.values(invalid);

    for (let i = 0; i < invalidVals.length; i++) {
      if (invalidVals[i]) {
        return false;
      }
    }

    if (this.props.openHearing) {
      return false;
    }

    return true;
  };

  completeScheduleHearingTask = () => {

    const {
      appeal,
      scheduleHearingTask, history,
      selectedHearingDay, selectedRegionalOffice,
      selectedHearingLocation
    } = this.props;

    const appealHearingLocations = appeal.availableHearingLocations || [];
    const hearingLocation = selectedHearingLocation || appealHearingLocations[0];

    const payload = {
      data: {
        task: {
          status: 'completed',
          business_payloads: {
            description: 'Update Task',
            values: {
              regional_office_value: selectedRegionalOffice,
              hearing_day_id: selectedHearingDay.hearingId,
              hearing_time: this.getHearingTime(),
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
    const { selectedRegionalOffice } = this.props;

    if (selectedRegionalOffice === 'C') {
      return [
        { displayText: '9:00 am',
          value: '9:00' },
        { displayText: '1:00 pm',
          value: '13:00' },
        { displayText: 'Other',
          value: 'other' }
      ];
    }

    return [
      { displayText: '8:30 am',
        value: '8:30' },
      { displayText: '12:30 pm',
        value: '12:30' },
      { displayText: 'Other',
        value: 'other' }
    ];
  };

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

  getHearingTime = () => {
    const { selectedHearingTime, selectedOptionalTime, selectedHearingDay } = this.props;

    if (!selectedHearingTime && !selectedOptionalTime) {
      return null;
    }

    const hearingTime = selectedHearingTime === 'other' ? selectedOptionalTime.value : selectedHearingTime;

    return {
      // eslint-disable-next-line id-length
      h: hearingTime.split(':')[0],
      // eslint-disable-next-line id-length
      m: hearingTime.split(':')[1],
      offset: moment.tz(selectedHearingDay.hearingDate, 'America/New_York').format('Z')
    };
  }

  getInitialValues = () => {
    const { hearingDay } = this.props;

    return {
      hearingDate: hearingDay.hearingDate,
      regionalOffice: this.getRO()
    };
  };

  render = () => {
    const {
      selectedHearingDay, selectedRegionalOffice, appeal,
      selectedHearingTime, openHearing, selectedHearingLocation,
      selectedOptionalTime
    } = this.props;

    const { invalid } = this.state;

    const initVals = this.getInitialValues();
    const timeOptions = this.getTimeOptions();
    const { address_line_1, city, state, zip } = appeal.appellantAddress || {};

    const currentRegionalOffice = selectedRegionalOffice || initVals.regionalOffice;
    const roIsDifferent = appeal.closestRegionalOffice !== currentRegionalOffice;
    let staticHearingLocations = _.isEmpty(appeal.availableHearingLocations) ?
      null : appeal.availableHearingLocations;

    if (roIsDifferent) {
      staticHearingLocations = null;
    }

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
        <RegionalOfficeDropdown
          onChange={this.props.onRegionalOfficeChange}
          errorMessage={invalid.regionalOffice}
          value={selectedRegionalOffice || initVals.regionalOffice}
          validateValueOnMount />

        {selectedRegionalOffice && <AppealHearingLocationsDropdown
          errorMessage={invalid.location}
          label="Suggested Hearing Location"
          key={`ahl-dropdown__${currentRegionalOffice || ''}`}
          regionalOffice={currentRegionalOffice}
          appealId={appeal.externalId}
          dynamic={staticHearingLocations === null || roIsDifferent}
          staticHearingLocations={staticHearingLocations}
          onChange={this.props.onHearingLocationChange}
          value={selectedHearingLocation}
        />}

        {selectedRegionalOffice && <HearingDateDropdown
          errorMessage={invalid.day}
          key={selectedRegionalOffice}
          regionalOffice={selectedRegionalOffice}
          onChange={this.props.onHearingDayChange}
          value={selectedHearingDay || initVals.hearingDate}
          validateValueOnMount
        />}
        <span {...formStyling}>
          <RadioField
            errorMessage={invalid.time}
            name="time"
            label="Time"
            strongLabel
            options={timeOptions}
            onChange={this.props.onHearingTimeChange}
            value={selectedHearingTime} />
        </span>
        {selectedHearingTime === 'other' && <SearchableDropdown
          name="optionalTime"
          placeholder="Select a time"
          options={TIME_OPTIONS}
          value={selectedOptionalTime || initVals.hearingDate}
          onChange={(value, label) => this.onHearingOptionalTime({ value,
            label })}
          hideLabel />}
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
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  regionalOfficeOptions: state.components.regionalOffices,
  hearingDay: state.ui.hearingDay,
  selectedHearingDay: state.components.selectedHearingDay,
  selectedHearingTime: state.components.selectedHearingTime,
  selectedOptionalTime: state.components.selectedOptionalTime,
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
  onHearingOptionalTime,
  onHearingLocationChange,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(AssignHearingModal)));
