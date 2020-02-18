import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { COLORS } from '../../../constants/AppConstants';
import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import Button from '../../../components/Button';
import StatusMessage from '../../../components/StatusMessage';
import COPY from '../../../../COPY';

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
  onSelectedHearingDayChange
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
              onClick={() => onSelectedHearingDayChange(hearingDay)}
              linkStyling>
              {`${moment(hearingDay.scheduledFor).format('ddd M/DD/YYYY')}
              ${hearingDay.room}`}
            </Button>
          </li>;
        })}
    </ul>
  </div>
);

UpcomingHearingDaysNav.propTypes = {
  upcomingHearingDays: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string,
    room: PropTypes.string
  }),
  onSelectedHearingDayChange: PropTypes.func
};

export default class AssignHearings extends React.Component {

  room = () => {
    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    // St. Petersburg, FL or Winston-Salem, NC
    if (selectedRegionalOffice === 'RO17' || selectedRegionalOffice === 'RO18') {
      if (selectedHearingDay) {
        return selectedHearingDay.room;
      }
    }

    return '';
  };

  render() {
    const {
      upcomingHearingDays,
      selectedHearingDay,
      selectedRegionalOffice,
      onSelectedHearingDayChange
    } = this.props;
    const room = this.room();

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
          room={room}
        />
      </React.Fragment>
    );
  }
}

AssignHearings.propTypes = {
  selectedRegionalOffice: PropTypes.string,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  userId: PropTypes.number
};
