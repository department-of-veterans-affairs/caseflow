import React from 'react';

import { CENTRAL_OFFICE_HEARING_LABEL, VIRTUAL_HEARING_LABEL, VIDEO_HEARING_LABEL } from '../../constants';
import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';
import { TimeSlotCard } from './TimeSlotCard';
import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import { roTimezones } from '../../utils';

export default {
  title: 'Hearings/Components/Assign Hearings/TimeSlotCard',
  component: TimeSlotCard,
  argTypes: {
    hearing: { table: { disable: true } },
  }
};

const Template = (args) => {
  if (args.showType) {
    args.caseType = 'Original';
    args.requestType = CENTRAL_OFFICE_HEARING_LABEL;
  }

  return (
    <TimeSlotCard
      hearing={{
        regionalOfficeTimezone: args.regionalOfficeTimezone,
        appellantFirstName: args.appellantFirstName,
        appellantLastName: args.appellantLastName,
        veteranFirstName: args.veteranFirstName,
        veteranLastName: args.veteranLastName,
        veteranFileNumber: args.veteranFileNumber,
        aod: args.aod,
        scheduledTimeString: args.scheduledTimeString,
        issueCount: args.issueCount,
        docketName: args.docketName,
        caseType: args.caseType,
        appealId: args.appealId,
        requestType: args.requestType,
        label: args.label,
        docketNumber: args.docketNumber,
        showDetails: args.showDetails,
        showType: args.showType,
        isFormerTravel: args.isFormerTravel,
        itemSpacing: args.itemSpacing,
        poaName: args.poaName
      }}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = {
  regionalOfficeTimezone: roTimezones()[1],
  scheduledTimeString: HEARING_TIME_OPTIONS[0].value,
  currentIssueCount: 1,
  veteranFirstName: 'John',
  veteranLastName: 'Doe',
  veteranFileNumber: '987654321',
  docketName: 'hearings',
  caseType: 'Original',
  poaName: 'American Legion',
  docketNumber: '1800000A',
  readableRequestType: CENTRAL_OFFICE_HEARING_LABEL
};

Basic.argTypes = {
  hearingTime: {
    control: {
      type: 'select',
      options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
    },
  },
  regionalOfficeTimezone: { control: { type: 'select', options: roTimezones() } },
  caseType: {
    control: {
      type: 'select',
      options: ['Original', LEGACY_APPEAL_TYPES.CAVC_REMAND],
    },
  },
  readableRequestType: {
    control: {
      type: 'select',
      options: [
        CENTRAL_OFFICE_HEARING_LABEL,
        VIRTUAL_HEARING_LABEL,
        VIDEO_HEARING_LABEL,
      ],
    },
  },
  currentIssueCount: { control: { type: 'number' } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
};
