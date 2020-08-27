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
import { RepresentativeSection } from './VirtualHearings/RepresentativeSection';
import { AppellantSection } from './VirtualHearings/AppellantSection';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { marginTop, regionalOfficeSection, saveButton, cancelButton } from './details/style';
import { isEmpty, orderBy } from 'lodash';
import COPY from '../../../COPY';

export const ScheduleVeteranForm = ({
  appeal,
  hearing,
  errors,
  initialRegionalOffice,
  initialHearingDate,
  ...props
}) => {
  const appellantTitle = getAppellantTitleForHearing(appeal);
  const ro = appeal.regionalOffice || hearing.regionalOffice || initialRegionalOffice;
  const location = appeal.hearingLocation || hearing.location;
  const header = `Schedule ${appellantTitle} for a Hearing`;
  const virtual = hearing?.virtualHearing;
  const video = hearing?.readableRequestType === 'Video';
  const availableHearingLocations = orderBy(appeal.availableHearingLocations || [], ['distance'], ['asc']);
  const dynamic = ro !== appeal.closestRegionalOffice || isEmpty(appeal.availableHearingLocations);

  const handleChange = () => {
    if (virtual) {
      return props.onChange('hearing', { virtualHearing: null });
    }

    return props.onChange('hearing', { virtualHearing: { status: 'pending' } });
  };

  return (
    <div {...regionalOfficeSection}>
      <AppSegment filledBackground >
        <h1>{header}</h1>
        {virtual ? <span>{COPY.SCHEDULE_VETERAN_DIRECT_TO_VIRTUAL_HELPER_LABEL}</span> : <div {...marginTop(45)} />}
        <div className="usa-width-one-half">
          <HearingTypeDropdown
            enableFullPageConversion
            update={handleChange}
            requestType={hearing.readableRequestType}
            virtualHearing={hearing?.virtualHearing}
          />
        </div>
        <div className="cf-help-divider usa-width-one-whole" />
        {virtual ? (
          <React.Fragment>

            <div className="usa-width-one-half" >
              <ReadOnly spacing={0} label="Regional Office" text={appeal.regionalOffice || 'Central'} />
              <ReadOnly spacing={15} label="Hearing Location" text={appeal.hearingLocation?.name || 'Virtual'} />

            </div>
            <div {...marginTop(15)} className="usa-width-one-half">
              <HearingDateDropdown
                errorMessage={errors?.hearingDay}
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={appeal.hearingDay || initialHearingDate}
                onChange={(hearingDay) => props.onChange('appeal', { hearingDay })}
              />
            </div>
            <div {...marginTop(15)} className="usa-width-one-half" >
              <HearingTime
                vertical
                errorMessage={errors?.scheduledTimeString}
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('hearing', { scheduledTimeString })}
                value={hearing.scheduledTimeString}
              />
            </div>
            <div className="cf-help-divider usa-width-one-whole" />
            <AppellantSection
              virtual={virtual}
              errors={errors}
              video={video}
              update={(_, virtualHearing) => props.onChange('hearing', virtualHearing)}
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
            <RepresentativeSection
              virtual={virtual}
              errors={errors}
              video={video}
              update={(_, virtualHearing) =>
                props.onChange('hearing', {
                  virtualHearing: {
                    ...hearing?.virtualHearing,
                    ...virtualHearing,
                  },
                })
              }
              appellantTitle={appellantTitle}
              hearing={hearing}
              virtualHearing={hearing?.virtualHearing}
              type={HEARING_CONVERSION_TYPES[0]}
            />
          </React.Fragment>
        ) : (
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
                  value={appeal.hearingDay}
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
          </div>)}
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
