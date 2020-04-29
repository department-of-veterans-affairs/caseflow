import PropTypes from 'prop-types';
import React, { useContext, useEffect } from 'react';
import _ from 'lodash';

import { HearingsFormContext, UPDATE_ASSIGN_HEARING } from '../../contexts/HearingsFormContext';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../../components/DataDropdowns';
import ApiUtil from '../../../util/ApiUtil';
import HearingTime from './HearingTime';

const AssignHearingForm = (props) => {
  const { appeal, initialRegionalOffice, initialHearingDate, showErrorMessages } = props;

  const hearingsFormContext = useContext(HearingsFormContext);
  const assignHearingForm = hearingsFormContext.state.hearingForms?.assignHearingForm || {};
  const { hearingLocation, hearingDay, scheduledTimeString } = assignHearingForm;
  const availableHearingLocations = _.orderBy(appeal.availableHearingLocations || [], ['distance'], ['asc']);
  const regionalOffice = assignHearingForm.regionalOffice || initialRegionalOffice;
  const dynamic = regionalOffice !== appeal.closestRegionalOffice || _.isEmpty(availableHearingLocations);

  useEffect(
    () => {
      const getErrorMessages = () => {
        const errorMessages = {
          hearingDay: hearingDay?.hearingId ? null : 'Please select a hearing date',
          hearingLocation: hearingLocation ? null : 'Please select a hearing location',
          scheduledTimeString: scheduledTimeString ? null : 'Please select a hearing time'
        };

        return {
          ...errorMessages,
          hasErrorMessages: (
            errorMessages.hearingDay ||
            errorMessages.hearingLocation ||
            errorMessages.scheduledTimeString
          )
        };
      };

      const getApiFormattedValues = () => {
        return {
          scheduled_time_string: scheduledTimeString,
          hearing_day_id: hearingDay?.hearingId,
          hearing_location: hearingLocation ? ApiUtil.convertToSnakeCase(hearingLocation) : null
        };
      };

      hearingsFormContext.dispatch({
        type: UPDATE_ASSIGN_HEARING,
        payload: {
          errorMessages: getErrorMessages(),
          apiFormattedValues: getApiFormattedValues()
        }
      });
    },
    [hearingDay, hearingLocation, scheduledTimeString]
  );

  const getErrorMessage = (valueKey) => {
    if (showErrorMessages) {
      return assignHearingForm.errorMessages[valueKey];
    }

    return '';
  };

  const onRegionalOfficeChange = (regionalOfficeVal) => {
    const newValues = {
      regionalOffice: regionalOfficeVal,
      hearingLocation: null,
      scheduledTimeString: null,
      hearingDay: null
    };

    hearingsFormContext.dispatch({
      type: UPDATE_ASSIGN_HEARING,
      payload: newValues
    });
  };

  return (
    <div>
      <RegionalOfficeDropdown
        value={regionalOffice}
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
          onChange={(value) => {
            hearingsFormContext.dispatch({
              type: UPDATE_ASSIGN_HEARING,
              payload: { hearingLocation: value }
            });
          }}
        />
        <HearingDateDropdown
          errorMessage={getErrorMessage('hearingDay')}
          key={`hearingDate__${regionalOffice}`}
          regionalOffice={regionalOffice}
          value={hearingDay || initialHearingDate}
          onChange={(value) => {
            hearingsFormContext.dispatch({
              type: UPDATE_ASSIGN_HEARING,
              payload: { hearingDay: value }
            });
          }}
          validateValueOnMount
        />
        <HearingTime
          errorMessage={getErrorMessage('scheduledTimeString')}
          key={`hearingTime__${regionalOffice}`}
          regionalOffice={regionalOffice}
          value={scheduledTimeString}
          onChange={(value) => {
            hearingsFormContext.dispatch({
              type: UPDATE_ASSIGN_HEARING,
              payload: { scheduledTimeString: value }
            });
          }}
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
