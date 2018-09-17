import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import StickyNavContentArea from '../../components/StickyNavContentArea';
import RoSelectorDropdown from './RoSelectorDropdown';
import AvailableHearingDay from './AvailableHearingDay';

export default class AssignHearings extends React.Component {
  render() {
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
      <StickyNavContentArea>
        <AvailableHearingDay
          title="Hearing day #1"
        />
        <AvailableHearingDay
          title="Hearing day #2"
        />
      </StickyNavContentArea>
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  onRegionalOfficeChange: PropTypes.func,
  selectedRegionalOffice: PropTypes.object
};
