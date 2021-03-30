import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { COLORS } from '../../../constants/AppConstants';
import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import HearingDayInfoButton from './HearingDayInfoButton';

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
const roSelectionStyling = css({ marginTop: '10px', textAlign: 'center' });

const UpcomingHearingDaysNav = ({
  upcomingHearingDays, selectedHearingDay,
  onSelectedHearingDayChange
}) => {
  const orderedHearingDays = _.orderBy(
    Object.values(upcomingHearingDays),
    (hearingDay) => hearingDay.scheduledFor, 'asc'
  );

  return (
    <div className="usa-width-one-fourth" {...roSelectionStyling}>
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {
          orderedHearingDays.map(
            (hearingDay) => {
              const selected = selectedHearingDay?.id === hearingDay?.id;

              return (
                <li key={hearingDay.id} >
                  <HearingDayInfoButton
                    selected={selected}
                    hearingDay={hearingDay}
                    onSelectedHearingDayChange={onSelectedHearingDayChange}
                  />
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
