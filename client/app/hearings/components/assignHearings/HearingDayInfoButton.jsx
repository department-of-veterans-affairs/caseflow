import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment';

import Button from '../../../components/Button';
import {
  buttonSelectedStyle,
  buttonUnselectedStyle,
  dateStyle,
  leftColumnStyle,
  rightColumnStyle,
  typeAndJudgeStyle
} from './styles';

import { formatHearingType, formatVljName, formatSlotRatio } from '../../utils';

// Check if there's a judge assigned
const hearingDayHasJudge = (hearingDay) => hearingDay.judgeFirstName && hearingDay.judgeLastName;
// Check if there's a room assigned (there never is for virtual)
const hearingDayHasRoom = (hearingDay) => Boolean(hearingDay.room);
// Check if there's a judge or room assigned
const hearingDayHasJudgeOrRoom = (hearingDay) => hearingDayHasJudge(hearingDay) || hearingDayHasRoom(hearingDay);
// Make the '·' separator appear or disappear
const separatorIfJudgeOrRoomPresent = (hearingDay) => hearingDayHasJudgeOrRoom(hearingDay) ? '·' : '';
// This is necessecary otherwise 'null' is displayed when there's no room or judge
const formatHearingRoom = (hearingDay) => hearingDay.room ? hearingDay.room : '';

export const HearingDayInfoButton = ({ hearingDay, selected, onSelectedHearingDayChange }) => {
  const formattedHearingType = formatHearingType(hearingDay.readableRequestType);
  const judgeOrRoom = hearingDayHasJudge(hearingDay) ? formatVljName(hearingDay) : formatHearingRoom(hearingDay);
  const separator = separatorIfJudgeOrRoomPresent(hearingDay);
  const formattedSlotRatio = formatSlotRatio(hearingDay);
  const formattedDate = moment(hearingDay.scheduledFor).format('ddd MMM Do');
  const classNames = selected ? ['selected-hearing-day-info-button'] : ['unselected-hearing-day-info-button'];

  return (
    <Button
      styling={selected ? buttonSelectedStyle : buttonUnselectedStyle}
      onClick={() => onSelectedHearingDayChange(hearingDay)}
      classNames={classNames}
      linkStyling>
      <div >
        <div {...leftColumnStyle} >
          <div {...dateStyle}>
            {formattedDate}
          </div>
          <div {...typeAndJudgeStyle}>
            {`${formattedHearingType} ${separator} ${judgeOrRoom}`}
          </div>
        </div>
        <div {...rightColumnStyle} >
          <div>
            {formattedSlotRatio}
          </div>
          <div>scheduled</div>
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
