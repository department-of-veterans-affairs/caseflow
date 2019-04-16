import React from 'react';
import _ from 'lodash';
import { css } from 'glamor';
import moment from 'moment';

import { getTimeWithoutTimeZone } from '../../util/DateUtil';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import { AppealHearingLocationsDropdown } from '../../components/DataDropdowns';
import HearingTime from './modalForms/HearingTime';
import { pencilSymbol } from '../../components/RenderFunctions';

import { DISPOSITION_OPTIONS } from '../../hearings/constants/constants';

const staticSpacing = css({ marginTop: '5px' });

const DispositionDropdown = ({
  hearing, update, readOnly, cancelHearingUpdate, openDispositionModal, saveHearing
}) => {

  return <div><SearchableDropdown
    name="Disposition"
    strongLabel
    options={DISPOSITION_OPTIONS}
    value={hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition}
    onChange={(option) => {
      openDispositionModal({
        hearing,
        disposition: option.value,
        onConfirm: () => {
          if (option.value === 'postponed') {
            cancelHearingUpdate();
          }

          update(option.value);
          saveHearing();
        }
      });
    }}
    readOnly={readOnly || !hearing.dispositionEditable}
  /></div>;
};

const TranscriptRequestedCheckbox = ({ hearing, readOnly, update }) => (
  <div>
    <b>Copy Requested by Appellant/Rep</b>
    <Checkbox
      label="Transcript Requested"
      name={`${hearing.id}.transcriptRequested`}
      value={_.isUndefined(hearing.editedTranscriptRequested) ?
        hearing.transcriptRequested || false : hearing.editedTranscriptRequested}
      onChange={(transcriptRequested) => update(transcriptRequested)}
      disabled={readOnly} />
  </div>
);

const HearingDetailsLink = ({ hearing }) => (
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

const StaticRegionalOffice = ({ hearing }) => (
  <div>
    <b>Regional Office</b><br />
    <div {...staticSpacing}>
      {hearing.readableRequestType === 'Central' ? hearing.readableRequestType : hearing.regionalOfficeName}<br />
    </div>
  </div>
);

const NotesField = ({ hearing, update, readOnly }) => (
  <TextareaField
    name="Notes"
    strongLabel
    disabled={readOnly}
    onChange={(notes) => update(notes)}
    textAreaStyling={css({ height: '50px' })}
    value={_.isUndefined(hearing.editedNotes) ? hearing.notes || '' : hearing.editedNotes}
  />
);

const HearingLocationDropdown = ({ hearing, readOnly, regionalOffice, update }) => {
  const currentRegionalOffice = hearing.editedRegionalOffice || regionalOffice;

  const roIsDifferent = currentRegionalOffice !== hearing.closestRegionalOffice;
  let staticHearingLocations = _.isEmpty(hearing.availableHearingLocations) ?
    [hearing.location] : _.values(hearing.availableHearingLocations);

  if (roIsDifferent) {
    staticHearingLocations = null;
  }

  return <AppealHearingLocationsDropdown
    readOnly={readOnly}
    appealId={hearing.appealExternalId}
    regionalOffice={currentRegionalOffice}
    staticHearingLocations={staticHearingLocations}
    dynamic={_.isEmpty(hearing.availableHearingLocations) || roIsDifferent}
    value={hearing.editedLocation || (hearing.location ? hearing.location.facilityId : null)}
    onChange={(hearingLocation) => update(hearingLocation)}
  />;
};

const StaticHearingDay = ({ hearing }) => (
  <div>
    <b>Hearing Day</b><br />
    <div {...staticSpacing}>{moment(hearing.scheduledFor).format('ddd M/DD/YYYY')} <br /> <br /></div>
  </div>
);

const TimeRadioButtons = ({ hearing, regionalOffice, update, readOnly }) => {
  const timezone = hearing.readableRequestType === 'Central' ? 'America/New_York' : hearing.regionalOfficeTimezone;

  const value = hearing.editedTime ? hearing.editedTime : getTimeWithoutTimeZone(hearing.scheduledFor, timezone);

  return <HearingTime
    regionalOffice={regionalOffice}
    value={value}
    readOnly={readOnly}
    onChange={(hearingTime) => update(hearingTime)} />;
};

const SaveButton = ({ hearing, cancelHearingUpdate, saveHearing }) => {
  return <div {...css({
    content: ' ',
    clear: 'both',
    display: 'block'
  })}>
    <Button
      styling={css({ float: 'left' })}
      linkStyling
      onClick={cancelHearingUpdate}>
      Cancel
    </Button>
    <Button
      styling={css({ float: 'right' })}
      disabled={hearing.dateEdited && !hearing.dispositionEdited}
      onClick={saveHearing}>
      Save
    </Button>
  </div>;
};

const inputSpacing = css({
  '& > div:not(:first-child)': {
    marginTop: '25px'
  }
});

export default class HearingActions extends React.Component {
  render () {
    const {
      hearing, readOnly, regionalOffice, openDispositionModal, user,
      cancelHearingUpdate, saveHearing, updateHearingTime, updateHearingNotes,
      updateHearingLocation, updateHearingDisposition, updateTranscriptRequested
    } = this.props;

    const inputProps = {
      hearing,
      readOnly
    };

    return <React.Fragment>
      <div {...inputSpacing}>
        <DispositionDropdown {...inputProps}
          update={updateHearingDisposition}
          cancelHearingUpdate={cancelHearingUpdate}
          saveHearing={saveHearing}
          openDispositionModal={openDispositionModal} />
        <TranscriptRequestedCheckbox {...inputProps} update={updateTranscriptRequested} />
        {user.userRoleAssign && <HearingDetailsLink hearing={hearing} />}
        <NotesField {...inputProps} update={updateHearingNotes} readOnly={user.userRoleVso} />
      </div>
      <div {...inputSpacing}>
        <StaticRegionalOffice hearing={hearing} />
        <HearingLocationDropdown {...inputProps} update={updateHearingLocation} regionalOffice={regionalOffice} />
        <StaticHearingDay hearing={hearing} />
        <TimeRadioButtons {...inputProps} update={updateHearingTime} regionalOffice={regionalOffice} />
        {hearing.edited &&
          <SaveButton
            hearing={hearing}
            cancelHearingUpdate={cancelHearingUpdate}
            saveHearing={saveHearing} />
        }
      </div>
    </React.Fragment>;
  }
}
