import React from 'react';

import { TimeSlotDetail } from './TimeSlotDetail';
import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';
import { CENTRAL_OFFICE_HEARING_LABEL, VIRTUAL_HEARING_LABEL, VIDEO_HEARING_LABEL } from '../../constants';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlot Detail',
  component: TimeSlotDetail,
  argTypes: {
    docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
    issueCount: { control: { type: 'number' } },
    poaName: { control: { type: 'select', options: ['', 'American Legion'] } },
  }
};

const Template = (args) => {
  if (args.showType) {
    args.caseType = 'Original';
    args.readableRequestType = CENTRAL_OFFICE_HEARING_LABEL;
  }

  return <TimeSlotDetail {...args} />;
};

export const Basic = Template.bind({});
Basic.args = {
  label: 'Something',
  showDetails: true,
  issueCount: 1,
  poaName: 'American Legion',
  docketName: 'legacy',
  docketNumber: '1800000A',
};

Basic.argTypes = {
  issueCount: { control: { type: 'number' } },
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
  docketName: {
    control: { type: 'select', options: ['', 'legacy', 'hearings'] },
  },
};
