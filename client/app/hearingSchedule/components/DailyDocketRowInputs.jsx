import React from 'react';
import _ from 'lodash';
import { css } from 'glamor';
import moment from 'moment';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import { AppealHearingLocationsDropdown } from '../../components/DataDropdowns';
import HearingTime from './modalForms/HearingTime';
import { pencilSymbol } from '../../components/RenderFunctions';

import { DISPOSITION_OPTIONS } from '../../hearings/constants/constants';

const staticSpacing = css({ marginTop: '5px' });

export const DispositionDropdown = ({
  hearing, update, readOnly, cancelUpdate, openDispositionModal, saveHearing
}) => {

  return <div><SearchableDropdown
    name={`${hearing.externalId}-disposition`}
    label="Disposition"
    strongLabel
    options={DISPOSITION_OPTIONS}
    value={hearing.disposition}
    onChange={(option) => {
      openDispositionModal({
        hearing,
        disposition: option.value,
        onConfirm: () => {
          if (option.value === 'postponed') {
            cancelUpdate();
          }

          update({ disposition: option.value });

          // give redux time to update
          setTimeout(saveHearing, 0);
        }
      });
    }}
    readOnly={readOnly || !hearing.dispositionEditable}
  /></div>;
};

export const Waive90DayHoldCheckbox = ({ hearing, readOnly, update }) => (
  <div>
    <b>Waive 90 Day Evidence Hold</b>
    <Checkbox
      label="Yes, Waive 90 Day Hold"
      name={`${hearing.externalId}-evidenceWindowWaived`}
      value={hearing.evidenceWindowWaived || false}
      onChange={(evidenceWindowWaived) => update({ evidenceWindowWaived })}
      disabled={readOnly} />
  </div>
);

export const TranscriptRequestedCheckbox = ({ hearing, readOnly, update }) => (
  <div>
    <b>Copy Requested by Appellant/Rep</b>
    <Checkbox
      label="Transcript Requested"
      name={`${hearing.externalId}-transcriptRequested`}
      value={hearing.transcriptRequested || false}
      onChange={(transcriptRequested) => update({ transcriptRequested })}
      disabled={readOnly} />
  </div>
);

export const HearingDetailsLink = ({ hearing }) => (
  <div>
    <b>Hearing Details</b><br />
    <div {...staticSpacing}>
      <Link href={`/hearings/${hearing.externalId}/details`}>
        Edit Hearing Details
        <span {...css({ position: 'absolute' })}>
          {pencilSymbol()}
        </span>
      </Link>
    </div>
  </div>
);

export const AodDropdown = ({ hearing, readOnly, update }) => {
  return <SearchableDropdown
    label="AOD"
    readOnly={true || readOnly}
    name={`${hearing.externalId}-aod`}
    strongLabel
    options={[{ value: 'granted',
      label: 'Granted' },
    { value: 'filed',
      label: 'Filed' },
    { value: 'none',
      label: 'None' }]}
    onChange={(aod) => update({ aod })}
    value={hearing.aod}
    searchable={false}
  />;
};

export const AodReasonDropdown = ({ hearing, readOnly, update }) => {
  return <SearchableDropdown
    label="AOD Reason"
    readOnly={true || readOnly}
    name={`${hearing.externalId}-aodReason`}
    strongLabel
    options={[]}
    onChange={(option) => update({ aodReason: (option || {}).value })}
    value={hearing.aodReason}
    searchable={false}
  />;
};

export const HearingPrepWorkSheetLink = ({ hearing }) => (
  <div>
    <b>Hearing Prep Worksheet</b><br />
    <div {...staticSpacing}>
      <Link href={`/hearings/${hearing.externalId}/worksheet`}>
        Edit VLJ Hearing Worksheet
        <span {...css({ position: 'absolute' })}>
          {pencilSymbol()}
        </span>
      </Link>
    </div>
  </div>
);

export const StaticRegionalOffice = ({ hearing }) => (
  <div>
    <b>Regional Office</b><br />
    <div {...staticSpacing}>
      {hearing.readableRequestType === 'Central' ? hearing.readableRequestType : hearing.regionalOfficeName}<br />
    </div>
  </div>
);

export const NotesField = ({ hearing, update, readOnly }) => {
  const disabled = readOnly || ['postponed', 'cancelled'].indexOf(hearing.disposition) > -1;

  return <TextareaField
    label="Notes"
    name={`${hearing.externalId}-notes`}
    strongLabel
    disabled={disabled}
    onChange={(notes) => update({ notes })}
    textAreaStyling={css({ height: '50px' })}
    value={hearing.notes || ''}
  />;
};

export const HearingLocationDropdown = ({ hearing, readOnly, regionalOffice, update }) => {
  const roIsDifferent = regionalOffice !== hearing.closestRegionalOffice;
  let staticHearingLocations = _.isEmpty(hearing.availableHearingLocations) ?
    [hearing.location] : _.values(hearing.availableHearingLocations);

  if (roIsDifferent) {
    staticHearingLocations = null;
  }

  return <AppealHearingLocationsDropdown
    readOnly={readOnly}
    appealId={hearing.appealExternalId}
    regionalOffice={regionalOffice}
    staticHearingLocations={staticHearingLocations}
    dynamic={_.isEmpty(hearing.availableHearingLocations) || roIsDifferent}
    value={hearing.location ? hearing.location.facilityId : null}
    onChange={(location) => update({ location })}
  />;
};

export const HoldOpenDropdown = ({ hearing, readOnly, update }) => (
  <SearchableDropdown
    label="Hold Open"
    name={`${hearing.externalId}-holdOpen`}
    strongLabel
    options={[0, 30, 60, 90].map((days) => ({
      value: days,
      label: `${days} days - ${moment(hearing.scheduledFor).add(days, 'days').
        format('MM/DD')}`
    }))}
    readOnly={readOnly}
    onChange={(option) => update({ holdOpen: (option || {}).value })}
    value={hearing.holdOpen}
    searchable={false} />
);

export const StaticHearingDay = ({ hearing }) => (
  <div>
    <b>Hearing Day</b><br />
    <div {...staticSpacing}>{moment(hearing.scheduledFor).format('ddd M/DD/YYYY')} <br /> <br /></div>
  </div>
);

export const TimeRadioButtons = ({ hearing, regionalOffice, update, readOnly }) => {
  return <HearingTime
    regionalOffice={regionalOffice}
    value={hearing.scheduledTimeString}
    readOnly={readOnly}
    onChange={(scheduledTimeString) => update({ scheduledTimeString })} />;
};

export const PreppedCheckbox = ({ hearing, update, readOnly }) => (
  <div>
    <Checkbox
      label={<span style={{ fontSize: 0 }}>Accessibility hack</span>}
      disabled={readOnly}
      name={`checkbox-prepped-${hearing.externalId}`}
      value={hearing.prepped || false}
      onChange={(prepped) => update({ prepped })} />
  </div>
);
