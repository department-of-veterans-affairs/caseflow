/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../components/DataDropdowns';
import { AddressLine } from './details/Address';
import { getAppellantTitleForHearing } from '../utils';
import { ReadOnly } from './details/ReadOnly';
import HearingTypeDropdown from './details/HearingTypeDropdown';
import { HearingTime } from './modalForms/HearingTime';
import Button from '../../components/Button';
import { marginTop, regionalOfficeSection, saveButton, cancelButton } from './details/style';
import { isEmpty, orderBy } from 'lodash';

export const ScheduleVeteranForm = ({ appeal, hearing, errors, initialRegionalOffice, initialHearingDate, ...props }) => {
  const appellantTitle = getAppellantTitleForHearing(appeal);
  const ro = appeal.regionalOffice || hearing.regionalOffice || initialRegionalOffice;
  const location = appeal.hearingLocation || hearing.location;
  const header = `Schedule ${appellantTitle} for a Hearing`;
  const availableHearingLocations = orderBy(appeal.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = ro !== appeal.closestRegionalOffice || isEmpty(appeal.availableHearingLocations);

  return (
    <div {...regionalOfficeSection}>
      <AppSegment filledBackground >
        <h1>{header}</h1>
        <div {...marginTop(45)} />
        <div className="usa-width-one-half">
          <HearingTypeDropdown requestType={hearing.readableRequestType} />
        </div>
        <div className="cf-help-divider usa-width-one-whole" />
        <div className="usa-width-one-half" >
          <ReadOnly spacing={0} label={`${appellantTitle} Address`} text={
            <AddressLine
              spacing={5}
              name={appeal?.appellantFullName}
              addressLine1={appeal?.appellantAddress?.address_line_1}
              addressState={appeal?.appellantAddress?.state}
              addressCity={appeal?.appellantAddress?.city}
              addressZip={appeal?.appellantAddress?.zip}
            />}
          />
          <RegionalOfficeDropdown
            onChange={(regionalOffice) => props.onChange('appeal', { regionalOffice })}
            value={ro}
            validateValueOnMount
          />
          {ro && (
            <React.Fragment>
              <AppealHearingLocationsDropdown
                errorMessage={errors?.hearingLocation}
                key={`hearingLocation__${ro}`}
                regionalOffice={ro}
                appealId={appeal.externalId}
                value={location}
                onChange={(hearingLocation) => props.onChange('appeal', { hearingLocation })}
                dynamic={dynamic}
                staticHearingLocations={availableHearingLocations}
              />
              <HearingDateDropdown
                errorMessage={errors?.hearingDay}
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={appeal.hearingDay || initialHearingDate}
                onChange={(hearingDay) => props.onChange('appeal', { hearingDay })}
              />
              <HearingTime
                errorMessage={errors?.scheduledTimeString}
                vertical
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('hearing', { scheduledTimeString })}
                value={hearing.scheduledTimeString}
              />

            </React.Fragment>
          )}
        </div>
      </AppSegment>
      <Button
        name="Cancel"
        linkStyling
        onClick={() => props.goBack()}
        styling={cancelButton}
      >
          Cancel
      </Button>
      <span {...saveButton}>
        <Button
          name="Schedule"
          loading={props.loading}
          className="usa-button"
          onClick={() => props.submit()}
        >
          Schedule
        </Button>
      </span>
    </div>
  );
};

ScheduleVeteranForm.propTypes = {
  loading: PropTypes.bool,
  submit: PropTypes.func.isRequired,
  goBack: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  appeal: PropTypes.object,
  errors: PropTypes.object,
  hearing: PropTypes.object,
  initialRegionalOffice: PropTypes.string,
  initialHearingDate: PropTypes.string
};

/* eslint-enable camelcase */
