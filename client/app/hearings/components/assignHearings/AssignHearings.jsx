import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { COLORS } from '../../../constants/AppConstants';
import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import Button from '../../../components/Button';

import { VIDEO_HEARING_LABEL } from '../../constants';

const horizontalRuleStyling = css({
  border: 0,
  width: '90%',
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  margin: 'auto',
});

const sectionNavigationListStyling = css({
  '& > li': {
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const buttonCommonStyle = {
  width: '90%',
  paddingTop: '1em',
  paddingBottom: '1em',
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

const leftColumnStyle = css({ width: '67%', display: 'inline-block', textAlign: 'left' });
const rightColumnStyle = css({ width: '33%', display: 'inline-block', textAlign: 'right', overflowX: 'hidden', overflowY: 'hidden' });
const typeAndJudgeStyle = css({ textOverflow: 'ellipsis', overflowX: 'hidden', overflowY: 'hidden', whiteSpace: 'nowrap' });

const roSelectionStyling = css({ marginTop: '10px', textAlign: 'center' });

const UpcomingHearingDaysNav = ({
  upcomingHearingDays, selectedHearingDay,
  onSelectedHearingDayChange
}) => {
  const orderedHearingDays = _.orderBy(
    Object.values(upcomingHearingDays),
    (hearingDay) => hearingDay.scheduledFor, 'asc'
  );

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

  const separatorIfJudgeOrRoomPresent = (hearingDay) => hearingDayHasJudgeOrRoom(hearingDay) ? '-' : '';
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

  return (
    <div className="usa-width-one-fourth" {...roSelectionStyling}>
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {
          orderedHearingDays.map(
            (hearingDay) => {
              const dateSelected = selectedHearingDay?.id === hearingDay?.id;
              const formattedHearingType = formatHearingType(hearingDay.readableRequestType);
              const judgeOrRoom = hearingDayHasJudge(hearingDay) ? formatVljName(hearingDay) : formatHearingRoom(hearingDay);
              const separator = separatorIfJudgeOrRoomPresent(hearingDay);

              // This came from AssignHearingTabs, modified
              const scheduledHearings = _.get(hearingDay, 'hearings', {});
              const scheduledHearingCount = Object.keys(scheduledHearings).length;
              const availableSlotCount = _.get(selectedHearingDay, 'totalSlots', 0) - scheduledHearingCount;
              const formattedSlotRatio = `${scheduledHearingCount} of ${availableSlotCount}`;

              return (
                <li key={hearingDay.id} >
                  <Button
                    styling={dateSelected ? buttonSelectedStyle : buttonUnselectedStyle}
                    onClick={() => onSelectedHearingDayChange(hearingDay)}
                    linkStyling>
                    <div>
                      <div {...leftColumnStyle} >
                        <div>
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
                  <hr {...horizontalRuleStyling} />
                </li>
              );
            }
          )
        }
      </ul>
    </div>
  );
};

UpcomingHearingDaysNav.propTypes = {
  upcomingHearingDays: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string,
    room: PropTypes.string
  }),
  onSelectedHearingDayChange: PropTypes.func
};

export const AssignHearings = ({
  upcomingHearingDays, selectedHearingDay, selectedRegionalOffice, onSelectedHearingDayChange
}) => {

  if (_.isEmpty(upcomingHearingDays)) {
    return <NoUpcomingHearingDayMessage />;
  }

  return (
    <React.Fragment>
      <UpcomingHearingDaysNav
        upcomingHearingDays={upcomingHearingDays}
        selectedHearingDay={selectedHearingDay}
        onSelectedHearingDayChange={onSelectedHearingDayChange} />
      <AssignHearingsTabs
        selectedRegionalOffice={selectedRegionalOffice}
        selectedHearingDay={selectedHearingDay}
        room={selectedHearingDay?.room}
      />
    </React.Fragment>
  );
};

AssignHearings.propTypes = {
  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,

  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  userId: PropTypes.number
};
