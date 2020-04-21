import React, { useContext } from 'react';
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

const AssignHearingForm = (props) => {
  const { appeal, initialRegionalOffice, initialHearingDate, showErrorMessages } = props;

  const hearingsFormContext = useContext(HearingsFormContext);
  const assignHearingForm = hearingsFormContext.state.hearingForms?.assignHearingForm || {};
  const { regionalOffice, hearingLocation, hearingDay, scheduledTimeString } = assignHearingForm;
  const availableHearingLocations = _.orderBy(appeal.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = regionalOffice !== appeal.closestRegionalOffice || _.isEmpty(appeal.availableHearingLocations);

  const getErrorMessages = (newValues) => {
    const values = { ...assignHearingForm, ...newValues };

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
  };

  const getApiFormattedValues = (newValues) => {
    const values = { ...assignHearingForm, ...newValues };

    return {
      scheduled_time_string: values.scheduledTimeString,
      hearing_day_id: values.hearingDay ? values.hearingDay.hearingId : null,
      hearing_location: values.hearingLocation ? ApiUtil.convertToSnakeCase(values.hearingLocation) : null
    };
  };

  const getErrorMessage = (valueKey) => {
    if (showErrorMessages) {
      return assignHearingForm.errorMessages[valueKey];
    }

    return '';
  };

  const onChange = (newValues) => {
    hearingsFormContext.dispatch({ type: UPDATE_ASSIGN_HEARING,
      payload: {
        ...newValues,
        errorMessages: getErrorMessages(newValues),
        apiFormattedValues: getApiFormattedValues(newValues)
      } });
  };

  const onRegionalOfficeChange = (regionalOfficeVal) => {
    const newValues = {
      regionalOffice: regionalOfficeVal, hearingLocation: null, scheduledTimeString: null, hearingDay: null
    };

    onChange(newValues);
  };

  return (
    <div>
      <RegionalOfficeDropdown
        value={regionalOffice || initialRegionalOffice}
        onChange={onRegionalOfficeChange}
        validateValueOnMount
      />
      {regionalOffice && <React.Fragment>
        <AppealHearingLocationsDropdown
          errorMessage={getErrorMessage('hearingLocation')}
          key={`hearingLocation__${regionalOffice}`}
          regionalOffice={regionalOffice}
          appealId={appeal.externalId}
          dynamic={dynamic}
          staticHearingLocations={availableHearingLocations}
          value={hearingLocation}
          onChange={(value) => onChange({ hearingLocation: value })}
        />
        <HearingDateDropdown
          errorMessage={getErrorMessage('hearingDay')}
          key={`hearingDate__${regionalOffice}`}
          regionalOffice={regionalOffice}
          value={hearingDay || initialHearingDate}
          onChange={(value) => onChange({ hearingDay: value })}
          validateValueOnMount
        />
        <HearingTime
          errorMessage={getErrorMessage('scheduledTimeString')}
          key={`hearingTime__${regionalOffice}`}
          regionalOffice={regionalOffice}
          value={scheduledTimeString}
          onChange={(value) => onChange({ scheduledTimeString: value })}
        />
      </React.Fragment>}
    </div>
  );
};

AssignHearingForm.propTypes = {
  appeal: PropTypes.shape({
    availableHearingLocations: PropTypes.array,
    closestRegionalOffice: PropTypes.string,
    externalId: PropTypes.string
  }),
  hearingDay: PropTypes.object,
  initialHearingDate: PropTypes.object,
  initialRegionalOffice: PropTypes.string,
  scheduledTimeString: PropTypes.string,
  showErrorMessages: PropTypes.bool
};

export default AssignHearingForm;
