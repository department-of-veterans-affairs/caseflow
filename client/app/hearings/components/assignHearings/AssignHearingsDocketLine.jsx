import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment';

import LEGACY_APPEAL_TYPES_BY_ID from '../../../../constants/LEGACY_APPEAL_TYPES_BY_ID';

export const docketCutoffLineStyle = (_index, scheduledForText) => {
  const isEmpty = _index < 0;
  const index = isEmpty ? 0 : _index;
  const style = {
    [`& #table-row-${index + 1} td`]: {
      paddingTop: '35px'
    },
    [`& #table-row-${index}`]: {
      borderBottom: '2px solid #000',
      position: 'relative',
      '& td': {
        paddingBottom: '35px'
      },
      '& td:first-child::before': {
        content: `Schedule for ${scheduledForText}`,
        display: 'block',
        position: 'absolute',
        transform: 'translateY(calc(100% + 4px))',
        background: '#fff',
        padding: '10px 10px 10px 0px',
        height: '42px',
        fontWeight: 'bold'
      }
    }
  };

  const isEmptyStyle = isEmpty ? {
    '& th': {
      paddingBottom: '35px'
    },
    [`& #table-row-${index}`]: {
      borderTop: '2px solid #000',
      borderBottom: 0,
      '& td': {
        paddingTop: '35px',
        paddingBottom: '15px'
      },
      '& td:first-child::before': {
        transform: 'translateY(-165%)',
        content: `All veterans have been scheduled through ${scheduledForText}`
      }
    }
  } : {};

  return css(_.merge(style, isEmptyStyle));
};

const getAppealsInDocketRange = (appeals, endOfRange) => _.filter(appeals, (appeal) => (
  moment(appeal.attributes.docketRangeDate).isBefore(endOfRange) ||
  appeal.attributes.caseType === LEGACY_APPEAL_TYPES_BY_ID.cavc_remand ||
  appeal.attributes.aod
));

export const getIndexOfDocketLine = (appeals, endOfRange) => {
  if (_.isEmpty(appeals)) {
    return -1;
  }

  const numberOfAppealsInDocketRange = getAppealsInDocketRange(appeals, endOfRange).length;

  return numberOfAppealsInDocketRange - 1;
};
