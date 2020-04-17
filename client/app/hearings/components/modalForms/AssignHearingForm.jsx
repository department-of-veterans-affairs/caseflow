import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import ApiUtil from '../../../util/ApiUtil';

import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../../components/DataDropdowns';
import HearingTime from './HearingTime';
import { HearingsFormContext, UPDATE_ASSIGN_HEARING } from '../../contexts/HearingsFormContext';

class AssignHearingForm extends React.Component {
  getErrorMessages = (newValues) => {
    const values = { ...this.props.assignHearingForm, ...newValues };

    const errorMessages = {
      hearingDay: values.hearingDay && values.hearingDay.hearingId ?
        false : 'Please select a hearing date',
      hearingLocation: values.hearingLocation ? false : 'Please select a hearing location',
      scheduledTimeString: values.scheduledTimeString ? false : 'Please select a hearing time'
    };

    return {
      ...errorMessages,
      hasErrorMessages: (errorMessages.hearingDay || errorMessages.hearingLocation ||
        errorMessages.scheduledTimeString) !== false
    };
  }

  getApiFormattedValues = (newValues) => {
    const values = { ...this.props.assignHearingForm, ...newValues };

    return {
      scheduled_time_string: values.scheduledTimeString,
      hearing_day_id: values.hearingDay ? values.hearingDay.hearingId : null,
      hearing_location: values.hearingLocation ? ApiUtil.convertToSnakeCase(values.hearingLocation) : null
    };
  }

  onChange = (newValues) => {
    const { dispatch } = this.context;

    dispatch({ type: UPDATE_ASSIGN_HEARING,
      payload: {
        ...newValues,
        errorMessages: this.getErrorMessages(newValues),
        apiFormattedValues: this.getApiFormattedValues(newValues)
      } });
  }

  onRegionalOfficeChange = (regionalOffice) => {
    const newValues = { regionalOffice, hearingLocation: null, scheduledTimeString: null, hearingDay: null };

    this.onChange(newValues);
  }

  getErrorMessage = (valueKey) => {
    if (this.props.showErrorMessages) {
      return this.props.assignHearingForm.errorMessages[valueKey];
    }

    return '';
  }

  render() {
    const { regionalOffice, hearingLocation, hearingDay, scheduledTimeString } = this.props.assignHearingForm;
    const { appeal, initialRegionalOffice, initialHearingDate } = this.props;

    const availableHearingLocations = _.orderBy(appeal.availableHearingLocations || [], ['distance'], ['asc']);
    const dynamic = regionalOffice !== appeal.closestRegionalOffice || _.isEmpty(appeal.availableHearingLocations);

    return (
      <div>
        <RegionalOfficeDropdown
          value={regionalOffice || initialRegionalOffice}
          onChange={this.onRegionalOfficeChange}
          validateValueOnMount
        />
        {regionalOffice && <React.Fragment>
          <AppealHearingLocationsDropdown
            errorMessage={this.getErrorMessage('hearingLocation')}
            key={`hearingLocation__${regionalOffice}`}
            regionalOffice={regionalOffice}
            appealId={appeal.externalId}
            dynamic={dynamic}
            staticHearingLocations={availableHearingLocations}
            value={hearingLocation}
            onChange={(value) => this.onChange({ hearingLocation: value })}
          />
          <HearingDateDropdown
            errorMessage={this.getErrorMessage('hearingDay')}
            key={`hearingDate__${regionalOffice}`}
            regionalOffice={regionalOffice}
            value={hearingDay || initialHearingDate}
            onChange={(value) => this.onChange({ hearingDay: value })}
            validateValueOnMount
          />
          <HearingTime
            errorMessage={this.getErrorMessage('scheduledTimeString')}
            key={`hearingTime__${regionalOffice}`}
            regionalOffice={regionalOffice}
            value={scheduledTimeString}
            onChange={(value) => this.onChange({ scheduledTimeString: value })}
          />
        </React.Fragment>}
      </div>
    );
  }
}

AssignHearingForm.contextType = HearingsFormContext;

AssignHearingForm.propTypes = {
  appeal: PropTypes.shape({
    availableHearingLocations: PropTypes.array,
    closestRegionalOffice: PropTypes.string,
    externalId: PropTypes.string
  }),
  assignHearingForm: PropTypes.shape({
    errorMessages: PropTypes.object,
    regionalOffice: PropTypes.string,
    hearingLocation: PropTypes.object,
    hearingDay: PropTypes.object,
    scheduledTimeString: PropTypes.string
  }),
  hearingDay: PropTypes.object,
  initialHearingDate: PropTypes.object,
  initialRegionalOffice: PropTypes.string,
  scheduledTimeString: PropTypes.string,
  showErrorMessages: PropTypes.bool
};

export default AssignHearingForm;
