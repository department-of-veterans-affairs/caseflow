import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import { formatDateStr } from '../../util/DateUtil';
import RoSelectorDropdown from './RoSelectorDropdown';

export default class AssignHearings extends React.Component {
  render() {
    const availableHearingDays = this.props.upcomingHearingDays && <div className="usa-width-one-fourth">
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list">
        {Object.values(this.props.upcomingHearingDays).slice(0, 9).
          map((hearingDay) => {
            return <li key={hearingDay.id} >
              <Link
                to="#">
                {`${formatDateStr(hearingDay.hearingDate)} ${hearingDay.roomInfo}`}
              </Link>
            </li>;
          })}
      </ul>
    </div>;

    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
      </Link>
      <RoSelectorDropdown
        regionalOffices={this.props.regionalOffices}
        onChange={this.props.onRegionalOfficeChange}
        value={this.props.selectedRegionalOffice}
      />
      {availableHearingDays}
      <div></div>
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  onRegionalOfficeChange: PropTypes.func,
  selectedRegionalOffice: PropTypes.object,
  upcomingHearingDays: PropTypes.object
};
