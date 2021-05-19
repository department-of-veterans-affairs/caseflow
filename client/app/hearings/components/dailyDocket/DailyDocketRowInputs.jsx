import React from 'react';
import { isNil, isEmpty, values } from 'lodash';
import { css } from 'glamor';
import moment from 'moment';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import SearchableDropdown from '../../../components/SearchableDropdown';
import Checkbox from '../../../components/Checkbox';
import TextareaField from '../../../components/TextareaField';
import { AppealHearingLocationsDropdown } from '../../../components/DataDropdowns';
import { pencilSymbol } from '../../../components/RenderFunctions';
import PropTypes from 'prop-types';
import VirtualHearingLink from '../VirtualHearingLink';

import { DISPOSITION_OPTIONS } from '../../constants';
import { COLORS } from '../../../constants/AppConstants';
import COPY from '../../../../COPY';
import HEARING_DISPOSITION_TYPES from '../../../../constants/HEARING_DISPOSITION_TYPES';
import {
  virtualHearingRoleForUser,
  virtualHearingLinkLabelFull,
  VIRTUAL_HEARING_HOST
} from '../../utils';

const staticSpacing = css({ marginTop: '5px' });

export const DispositionDropdown = ({ hearing, update, readOnly, openDispositionModal, saveHearing }) => (
  <div>
    <SearchableDropdown
      name={`${hearing.externalId}-disposition`}
      label="Disposition"
      strongLabel
      options={DISPOSITION_OPTIONS}
      value={hearing.disposition}
      onChange={(option) => {
        if (!option) {
          return;
        }

        const fromDisposition = hearing?.disposition;
        const toDisposition = option.value;

        openDispositionModal({
          update,
          hearing,
          fromDisposition,
          toDisposition,
          onCancel: () => {
            update({ disposition: fromDisposition });
          },
          onConfirm: saveHearing
        });
      }}
      readOnly={readOnly || !hearing.dispositionEditable}
    />
  </div>
);

DispositionDropdown.propTypes = {
  hearing: PropTypes.object,
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  openDispositionModal: PropTypes.func,
  saveHearing: PropTypes.func
};

export const Waive90DayHoldCheckbox = ({ hearing, readOnly, update }) => (
  <div>
    <b>Waive 90 Day Evidence Hold</b>
    <Checkbox
      label="Yes, Waive 90 Day Hold"
      name={`${hearing.externalId}-evidenceWindowWaived`}
      value={hearing.evidenceWindowWaived || false}
      onChange={(evidenceWindowWaived) => update({ evidenceWindowWaived })}
      disabled={readOnly}
    />
  </div>
);

Waive90DayHoldCheckbox.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const TranscriptRequestedCheckbox = ({ hearing, readOnly, update }) => (
  <div>
    <b>Copy Requested by Appellant/Rep</b>
    <Checkbox
      label="Transcript Requested"
      name={`${hearing.externalId}-transcriptRequested`}
      value={hearing.transcriptRequested || false}
      onChange={(transcriptRequested) => update({ transcriptRequested })}
      disabled={readOnly}
    />
  </div>
);

TranscriptRequestedCheckbox.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const HearingDetailsLink = ({ hearing }) => (
  <div>
    <b>Hearing Details</b>
    <br />
    <div {...staticSpacing}>
      <Link to={`/${hearing.externalId}/details`}>
        Edit Hearing Details
        <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
      </Link>
    </div>
  </div>
);

HearingDetailsLink.propTypes = {
  hearing: PropTypes.object
};

export const LegacyAodDropdown = ({ hearing, readOnly, update }) => {
  return (
    <SearchableDropdown
      label="AOD"
      readOnly={readOnly}
      name={`${hearing.externalId}-aod`}
      strongLabel
      options={[
        { value: 'granted', label: 'Granted' },
        { value: 'filed', label: 'Filed' },
        { value: 'none', label: 'None' }
      ]}
      onChange={(option) => update({ aod: (option || {}).value })}
      value={hearing.aod}
      searchable={false}
    />
  );
};

LegacyAodDropdown.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const AmaAodDropdown = ({ hearing, readOnly, updateAodMotion, userId }) => {
  const aodMotion = hearing.advanceOnDocketMotion;

  return (
    <SearchableDropdown
      label="AOD"
      strongLabel
      readOnly={readOnly}
      name={`${hearing.externalId}-aod`}
      options={[{ value: true, label: 'Granted' }, { value: false, label: 'Denied' }]}
      value={aodMotion ? aodMotion.granted : null}
      searchable={false}
      onChange={(option) => {
        const granted = (option || {}).value;
        const value = { granted, userId };

        updateAodMotion(value);
      }}
    />
  );
};

AmaAodDropdown.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  updateAodMotion: PropTypes.func,
  userId: PropTypes.number
};

export const AodReasonDropdown = ({ hearing, readOnly, updateAodMotion, userId, invalid }) => {
  const aodMotion = hearing.advanceOnDocketMotion;
  const aodGrantableByThisUser = aodMotion && (aodMotion.userId === userId || isNil(aodMotion.userId));

  return (
    <SearchableDropdown
      label="AOD Reason"
      readOnly={readOnly || !aodGrantableByThisUser}
      required={aodMotion && !isNil(aodMotion.granted)}
      name={`${hearing.externalId}-aodReason`}
      errorMessage={invalid ? 'Please select an AOD reason' : null}
      strongLabel
      options={[
        { value: 'financial_distress', label: 'Financial Distress' },
        { value: 'age', label: 'Age' },
        { value: 'serious_illness', label: 'Serious Illness' },
        { value: 'other', label: 'Other' }
      ]}
      onChange={(option) => updateAodMotion({ reason: (option || {}).value })}
      value={aodMotion ? aodMotion.reason : null}
      searchable={false}
    />
  );
};

AodReasonDropdown.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  updateAodMotion: PropTypes.func,
  userId: PropTypes.number,
  invalid: PropTypes.bool
};

export const HearingPrepWorkSheetLink = ({ hearing }) => (
  <div>
    <b>Hearing Prep Worksheet</b>
    <br />
    <div {...staticSpacing}>
      <Link href={`/hearings/${hearing.externalId}/worksheet`}>
        Edit VLJ Hearing Worksheet
        <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
      </Link>
    </div>
  </div>
);

HearingPrepWorkSheetLink.propTypes = {
  hearing: PropTypes.object
};

export const StaticRegionalOffice = ({ hearing }) => (
  <div>
    <b>Regional Office</b>
    <br />
    <div {...staticSpacing}>
      {hearing.readableRequestType === 'Central' ? hearing.readableRequestType : hearing.regionalOfficeName}
      <br />
    </div>
  </div>
);

StaticRegionalOffice.propTypes = {
  hearing: PropTypes.object
};

export const NotesField = ({ hearing, update, readOnly }) => {
  const disabled = readOnly ||
    [HEARING_DISPOSITION_TYPES.postponed, HEARING_DISPOSITION_TYPES.cancelled].indexOf(hearing.disposition) > -1;

  return (
    <TextareaField
      maxlength={1000}
      label="Notes"
      name={`${hearing.externalId}-notes`}
      strongLabel
      disabled={disabled}
      onChange={(notes) => update({ notes })}
      textAreaStyling={css({ height: '100px' })}
      value={hearing.notes || ''}
    />
  );
};

NotesField.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const HearingLocationDropdown = ({ hearing, readOnly, regionalOffice, update }) => {
  const roIsDifferent = regionalOffice !== hearing.closestRegionalOffice;
  let staticHearingLocations = isEmpty(hearing.availableHearingLocations) ?
    [hearing.location] :
    values(hearing.availableHearingLocations);

  if (roIsDifferent) {
    staticHearingLocations = null;
  }

  return (
    <AppealHearingLocationsDropdown
      readOnly={readOnly}
      appealId={hearing.appealExternalId}
      regionalOffice={regionalOffice}
      staticHearingLocations={staticHearingLocations}
      dynamic={isEmpty(hearing.availableHearingLocations) || roIsDifferent}
      value={hearing.location ? hearing.location.facilityId : null}
      onChange={(location) => update({ location })}
    />
  );
};

HearingLocationDropdown.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  regionalOffice: PropTypes.string
};

export const HoldOpenDropdown = ({ hearing, readOnly, update }) => (
  <SearchableDropdown
    label="Hold Open"
    name={`${hearing.externalId}-holdOpen`}
    strongLabel
    options={[0, 30, 60, 90].map((days) => ({
      value: days,
      label: `${days} days - ${moment(hearing.scheduledFor).
        add(days, 'days').
        format('MM/DD')}`
    }))}
    readOnly={readOnly}
    onChange={(option) => update({ holdOpen: (option || {}).value })}
    value={hearing.holdOpen}
    searchable={false}
  />
);

HoldOpenDropdown.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const StaticHearingDay = ({ hearing }) => (
  <div>
    <b>Hearing Day</b>
    <br />
    <div {...staticSpacing}>
      {moment(hearing.scheduledFor).format('ddd M/DD/YYYY')} <br /> <br />
    </div>
  </div>
);

StaticHearingDay.propTypes = {
  hearing: PropTypes.object
};

export const PreppedCheckbox = ({ hearing, update, readOnly }) => (
  <div>
    <Checkbox
      label={<span style={{ fontSize: 0 }}>Accessibility hack</span>}
      disabled={readOnly}
      name={`checkbox-prepped-${hearing.externalId}`}
      value={hearing.prepped || false}
      onChange={(prepped) => update({ prepped })}
    />
  </div>
);

PreppedCheckbox.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  update: PropTypes.func
};

export const StaticVirtualHearing = ({ hearing, user }) => (
  <div>
    <VirtualHearingLink
      label={virtualHearingLinkLabelFull(virtualHearingRoleForUser(user, hearing))}
      user={user}
      hearing={hearing}
      isVirtual={hearing.isVirtual}
      virtualHearing={hearing.virtualHearing}
      link={
        virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST ?
        hearing?.virtualHearing?.hostLink :
        hearing?.virtualHearing?.guestLink
      }
    />
    {hearing?.virtualHearing?.status === 'pending' && (
      <div {...staticSpacing}>
        <span {...css({ color: COLORS.GREY_MEDIUM })}>{COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}</span>
      </div>
    )}
  </div>
);

StaticVirtualHearing.propTypes = {
  user: PropTypes.shape({
    userId: PropTypes.number
  }),
  hearing: PropTypes.shape({
    isVirtual: PropTypes.bool,
    judgeId: PropTypes.number,
    virtualHearing: PropTypes.shape({
      jobCompleted: PropTypes.bool
    })
  })
};
