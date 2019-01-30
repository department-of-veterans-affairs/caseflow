import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import Button from '../../components/Button';
import { css } from 'glamor';
import moment from 'moment';
import { COLORS } from '../../constants/AppConstants';
import AssignHearingsTabs from './AssignHearingsTabs';

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const buttonColorSelected = css({
  backgroundColor: COLORS.GREY_DARK,
  color: COLORS.WHITE,
  borderRadius: '0.1rem 0.1rem 0 0',
  '&:hover': {
    backgroundColor: COLORS.GREY_DARK,
    color: COLORS.WHITE
  }
});

const roSelectionStyling = css({ marginTop: '10px' });

const UpcomingHearingDaysNav = ({
  upcomingHearingDays, selectedHearingDay,
  onSelectedHearingDayChangeFactory, room
}) => (
  <div className="usa-width-one-fourth" {...roSelectionStyling}>
    <h3>Hearings to Schedule</h3>
    <h4>Available Hearing Days</h4>
    <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
      {_.orderBy(Object.values(upcomingHearingDays), (hearingDay) => hearingDay.scheduledFor, 'asc').
        map((hearingDay) => {
          const dateSelected = selectedHearingDay &&
          (selectedHearingDay.scheduledFor === hearingDay.scheduledFor &&
             selectedHearingDay.room === hearingDay.room);

          return <li key={hearingDay.id} >
            <Button
              styling={dateSelected ? buttonColorSelected : {}}
              onClick={onSelectedHearingDayChangeFactory(hearingDay)}
              linkStyling>
              {`${moment(hearingDay.scheduledFor).format('ddd M/DD/YYYY')}
              ${room}`}
            </Button>
          </li>;
        })}
    </ul>
  </div>
);

export default class AssignHearings extends React.Component {

  onSelectedHearingDayChangeFactory = (hearingDay) => () => {
    this.props.onSelectedHearingDayChange(hearingDay);
  };

  room = (hearingDay) => {
    // St. Petersburg, FL
    if (this.props.selectedRegionalOffice === 'RO17') {
      return hearingDay.room;
      // Winston-Salem, NC
    } else if (this.props.selectedRegionalOffice === 'RO18') {
      return hearingDay.room;
    }

    return '';
  };

  render() {
    const {
      upcomingHearingDays, selectedHearingDay,
      appealsReadyForHearing, selectedRegionalOffice
    } = this.props;
    const hasUpcomingHearingDays = !_.isEmpty(upcomingHearingDays);
    const room = this.room();

    return (
      <React.Fragment>
        {hasUpcomingHearingDays && <UpcomingHearingDaysNav
          upcomingHearingDays={upcomingHearingDays}
          selectedHearingDay={selectedHearingDay}
          onSelectedHearingDayChangeFactory={this.onSelectedHearingDayChangeFactory}
          room={room} />
        }
        {(hasUpcomingHearingDays && appealsReadyForHearing && selectedHearingDay) &&
          <AssignHearingsTabs
            selectedRegionalOffice={selectedRegionalOffice}
            selectedHearingDay={selectedHearingDay}
            appealsReadyForHearing={appealsReadyForHearing}
            room={room}
          />}
      </React.Fragment>
    );
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  selectedRegionalOffice: PropTypes.string,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.object,
  appealsReadyForHearing: PropTypes.object,
  userId: PropTypes.number,
  onReceiveTasks: PropTypes.func
};
