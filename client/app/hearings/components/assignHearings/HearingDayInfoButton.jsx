import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { COLORS } from '../../../constants/AppConstants';
import Button from '../../../components/Button';

import { VIDEO_HEARING_LABEL } from '../../constants';

const buttonCommonStyle = {
  width: '90%',
  paddingTop: '1.5rem',
  paddingBottom: '1.5rem',
};

const buttonUnselectedStyle = css(
  buttonCommonStyle
);

const buttonSelectedStyle = css(
  {
    ...buttonCommonStyle,
    ...{
      backgroundColor: COLORS.GREY_DARK,
      color: COLORS.WHITE,
      borderRadius: '0.1rem 0.1rem 0 0',
      '&:hover': {
        backgroundColor: COLORS.GREY_DARK,
        color: COLORS.WHITE
      }
    }
  });

const fontSizeStyle = css({ fontSize: '1.5rem' });

const dateStyle = css({ fontWeight: 'bold' });

const leftColumnStyle = css({
  width: '60%',
  display: 'inline-block',
  textAlign: 'left'
});
const rightColumnStyle = css({
  width: '40%',
  display: 'inline-block',
  textAlign: 'right',
  overflowX: 'hidden',
  overflowY: 'hidden'
});
const typeAndJudgeStyle = css({
  textOverflow: 'ellipsis',
  overflowX: 'hidden',
  overflowY: 'hidden',
  whiteSpace: 'nowrap'
});

// This came out of ListSchedule, should be refactored into common import
const formatHearingType = (hearingType) => {
  if (hearingType.toLowerCase().startsWith('video')) {
    return VIDEO_HEARING_LABEL;
  }

  return hearingType;
};
  // Check if there's a judge assigned
const hearingDayHasJudge = (hearingDay) => hearingDay.judgeFirstName && hearingDay.judgeLastName;
// Check if there's a room assigned (there never is for virtual)
const hearingDayHasRoom = (hearingDay) => Boolean(hearingDay.room);
// Check if there's a judge or room assigned
const hearingDayHasJudgeOrRoom = (hearingDay) => hearingDayHasJudge(hearingDay) || hearingDayHasRoom(hearingDay);

const separatorIfJudgeOrRoomPresent = (hearingDay) => hearingDayHasJudgeOrRoom(hearingDay) ? '·' : '';
// This is necessecary otherwise 'null' is displayed when there's no room or judge
const formatHearingRoom = (hearingDay) => hearingDay.room ? hearingDay.room : '';
// This came out of ListSchedule, should be refactored into common import
// I modified it though, will need to make that change in ListSchedule
const formatVljName = (hearingDay) => {
  const first = hearingDay?.judgeFirstName;
  const last = hearingDay?.judgeLastName;

  if (last && first) {
    return `${last}, ${first}`;
  }

  return '';
};

export const HearingDayInfoButton = ({ hearingDay, selected, onSelectedHearingDayChange }) => {
  const formattedHearingType = formatHearingType(hearingDay.readableRequestType);
  const judgeOrRoom = hearingDayHasJudge(hearingDay) ? formatVljName(hearingDay) : formatHearingRoom(hearingDay);
  const separator = separatorIfJudgeOrRoomPresent(hearingDay);

  // This came from AssignHearingTabs, modified, the slots dont match new work
  const scheduledHearings = _.get(hearingDay, 'hearings', {});
  const scheduledHearingCount = Object.keys(scheduledHearings).length;
  const availableSlotCount = _.get(hearingDay, 'totalSlots', 0) - scheduledHearingCount;
  const formattedSlotRatio = `${scheduledHearingCount} of ${availableSlotCount}`;

  return (
    <Button
      styling={selected ? buttonSelectedStyle : buttonUnselectedStyle}
      onClick={() => onSelectedHearingDayChange(hearingDay)}
      linkStyling>
      <div {...fontSizeStyle}>
        <div {...leftColumnStyle} >
          <div {...dateStyle}>
            {moment(hearingDay.scheduledFor).format('ddd MMM Do')}
          </div>
          <div {...typeAndJudgeStyle}>
            {`${formattedHearingType} ${separator} ${judgeOrRoom}`}
          </div>
        </div>
        <div {...rightColumnStyle} >
          <div>
            {formattedSlotRatio}
          </div>
          <div>
                          scheduled
          </div>
        </div>
      </div>
    </Button>
  );
};

HearingDayInfoButton.propTypes = {
  hearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  selected: PropTypes.bool,
  onSelectedHearingDayChange: PropTypes.func,
};

export default HearingDayInfoButton;
