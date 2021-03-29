import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { COLORS } from '../../../constants/AppConstants';
import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import Button from '../../../components/Button';

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

const buttonColorSelected = css({
  width: '90%',
  paddingTop: '1em',
  paddingBottom: '1em',
  backgroundColor: COLORS.GREY_DARK,
  color: COLORS.WHITE,
  borderRadius: '0.1rem 0.1rem 0 0',
  '&:hover': {
    backgroundColor: COLORS.GREY_DARK,
    color: COLORS.WHITE
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

  /*
                      {`${moment(hearingDay.scheduledFor).format('ddd M/DD/YYYY')}
                      ${hearingDay.room ?? ''}`
  */

  return (
    <div className="usa-width-one-fourth" {...roSelectionStyling}>
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {
          orderedHearingDays.map(
            (hearingDay) => {
              const dateSelected = selectedHearingDay?.id === hearingDay?.id;

              return (
                <li key={hearingDay.id} >
                  <Button
                    styling={dateSelected ? buttonColorSelected : css({ width: '90%', paddingTop: '1em', paddingBottom: '1em' })}
                    onClick={() => onSelectedHearingDayChange(hearingDay)}
                    linkStyling>
                    <div>
                      <div {...css({ width: '67%', display: 'inline-block', textAlign: 'left' })} >
                        <div>
                        Thu Apr 1
                        </div>
                        <div {...css({ textOverflow: 'ellipsis', overflowX: 'hidden', overflowY: 'hidden', whiteSpace: 'nowrap' })}>
                          Virtual * VLJVigsittaboorn
                        </div>
                      </div>
                      <div {...css({ width: '33%', display: 'inline-block', textAlign: 'right', overflowX: 'hidden', overflowY: 'hidden' })} >
                        <div>
                        2 of 4
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
