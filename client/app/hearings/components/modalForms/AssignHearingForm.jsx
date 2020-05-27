import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { HearingTime } from './HearingTime';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../../components/DataDropdowns';
import { onChangeFormData } from '../../../components/common/actions';
import ApiUtil from '../../../util/ApiUtil';

class AssignHearingForm extends React.Component {
  getErrorMessages = (newValues) => {
    const values = {
      ...this.props.values,
      ...newValues
    };

    const errorMessages = {
      hearingDay: (values.hearingDay && values.hearingDay.hearingId) ?
        null :
        'Please select a hearing date',
      hearingLocation: values.hearingLocation ? null : 'Please select a hearing location',
      scheduledTimeString: values.scheduledTimeString ? null : 'Please select a hearing time'
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
      scheduled_time_string: values.scheduledTimeString,
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

  getErrorMessage = (valueKey) => {
    if (this.props.showErrorMessages) {
      return this.props.values.errorMessages[valueKey];
    }

    return '';
  }

  render() {
    const { appeal, values, initialRegionalOffice, initialHearingDate } = this.props;
    const { regionalOffice, hearingLocation, hearingDay, scheduledTimeString } = values;
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

AssignHearingForm.propTypes = {
  appeal: PropTypes.shape({
    availableHearingLocations: PropTypes.arrayOf(PropTypes.object),
    closestRegionalOffice: PropTypes.string,
    externalId: PropTypes.string
  }),
  initialHearingDate: PropTypes.string,
  initialRegionalOffice: PropTypes.string,
  onChange: PropTypes.func,
  showErrorMessages: PropTypes.bool,
  values: PropTypes.shape({
    errorMessages: PropTypes.object,
    hearingDay: PropTypes.object,
    hearingLocation: PropTypes.object,
    regionalOffice: PropTypes.string,
    scheduledTimeString: PropTypes.string
  })
};

const mapStateToProps = (state) => ({
  values: state.components.forms.assignHearing || {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onChange: (value) => onChangeFormData('assignHearing', value)
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingForm);
