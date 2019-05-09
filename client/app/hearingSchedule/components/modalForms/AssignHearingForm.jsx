import React from 'react';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import ApiUtil from '../../../util/ApiUtil';

import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../../components/DataDropdowns';
import HearingTime from './HearingTime';

import { onChangeFormData } from '../../../components/common/actions';

class AssignHearingForm extends React.Component {

  /*
    This duplicates a lot of the logic from AssignHearingModal.jsx
    TODO: refactor so both of these modals use the same components
  */
  componentWillMount() {

    const { initialRegionalOffice, initialHearingDate, initialScheduledTimeString } = this.props;

    const values = {
      regionalOffice: initialRegionalOffice || null,
      hearingLocation: null,
      scheduledTimeString: initialScheduledTimeString || null,
      hearingDay: initialHearingDate || null
    };

    this.props.onChange({
      ...values,
      errorMessages: this.getErrorMessages(values),
      apiFormattedValues: this.getApiFormattedValues(values)
    });
  }

  getErrorMessages = (newValues) => {
    const values = {
      ...this.props.values,
      ...newValues
    };

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
    const values = {
      ...this.props.values,
      ...newValues
    };

    return {
      scheduledTimeString: values.scheduledTimeString,
      hearing_day_id: values.hearingDay ? values.hearingDay.hearingId : null,
      hearing_location: values.hearingLocation ? ApiUtil.convertToSnakeCase(values.hearingLocation) : null
    };
  }

  onChange = (newValues) => {
    this.props.onChange({
      ...newValues,
      errorMessages: this.getErrorMessages(newValues),
      apiFormattedValues: this.getApiFormattedValues(newValues)
    });
  }

  onRegionalOfficeChange = (regionalOffice) => {
    const newValues = {
      regionalOffice,
      hearingLocation: null,
      scheduledTimeString: null,
      hearingDay: null
    };

    this.onChange(newValues);
  }

  render() {
    const { appeal, showErrorMessages, values } = this.props;
    const { regionalOffice, hearingLocation, hearingDay, scheduledTimeString, errorMessages } = values;
    const availableHearingLocations = _.sortBy(appeal.availableHearingLocations || [], 'distance');

    return (
      <div>
        <RegionalOfficeDropdown
          value={regionalOffice}
          onChange={this.onRegionalOfficeChange}
          validateValueOnMount
        />
        {regionalOffice && <React.Fragment>
          <AppealHearingLocationsDropdown
            errorMessage={showErrorMessages ? errorMessages.hearingLocation : ''}
            key={`hearingLocation__${regionalOffice}`}
            regionalOffice={regionalOffice}
            appealId={appeal.externalId}
            dynamic={regionalOffice !== appeal.closestRegionalOffice ||
              _.isEmpty(appeal.availableHearingLocations)}
            staticHearingLocations={availableHearingLocations}
            value={hearingLocation}
            onChange={(value) => this.onChange({ hearingLocation: value })}
          />
          <HearingDateDropdown
            errorMessage={showErrorMessages ? errorMessages.hearingDay : ''}
            key={`hearingDate__${regionalOffice}`}
            regionalOffice={regionalOffice}
            value={hearingDay}
            onChange={(value) => this.onChange({ hearingDay: value })}
            validateValueOnMount
          />
          <HearingTime
            errorMessage={showErrorMessages ? errorMessages.scheduledTimeString : ''}
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

const mapStateToProps = (state) => ({
  values: state.components.forms.assignHearing || {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onChange: (value) => onChangeFormData('assignHearing', value)
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingForm);
