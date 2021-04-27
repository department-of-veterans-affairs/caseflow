import React from 'react';
import PropTypes from 'prop-types';
import { orderBy, debounce } from 'lodash';

import HearingDayInfoButton from './HearingDayInfoButton';
import { hearingDayListHorizontalRuleStyle, sectionNavigationListStyling, roSelectionStyling } from './styles';
import { groupHearingDays, selectHearingDayEvent } from '../../utils';

/**
 * Hearing Days Navigation Component
 * @param {Object} props -- Contains the hearing day list and selected hearing day
 */
export const HearingDaysNav = ({ upcomingHearingDays, selectedHearingDay, onSelectedHearingDayChange }) => {
  // Group the hearing days by month
  const hearingDays = groupHearingDays(upcomingHearingDays);

  // Send a google analytics event on scroll
  const handleScroll = debounce(() => window.analyticsEvent('Hearings', 'Available Hearing Days – Scroll '), 250);

  return (
    <div className="usa-width-one-sixth" {...roSelectionStyling}>
      <div className="hearing-day-list" onScroll={handleScroll}>
        <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
          {Object.keys(hearingDays).map((month) => (
            <React.Fragment key={month}>
              <label>{month}</label>
              {orderBy(hearingDays[month], 'scheduledFor', 'asc').map(
                (hearingDay) => (
                  <li key={hearingDay.id}>
                    <HearingDayInfoButton
                      id={hearingDay.id}
                      selected={selectedHearingDay?.id === hearingDay?.id}
                      hearingDay={hearingDay}
                      onSelectedHearingDayChange={selectHearingDayEvent(onSelectedHearingDayChange)}
                    />
                    <hr {...hearingDayListHorizontalRuleStyle} />
                  </li>
                ))}
            </React.Fragment>
          ))}
        </ul>
      </div>
    </div>
  );
};

HearingDaysNav.propTypes = {
  upcomingHearingDays: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string,
    room: PropTypes.string
  }),
  onSelectedHearingDayChange: PropTypes.func
};
