import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class AssignHearings extends React.Component {

  regionalOfficeOptions = () => {
    let regionalOfficeDropdowns = [];

    this.props.regionalOffices.forEach((value) => {
      regionalOfficeDropdowns.push({label: value, value: value});
    });

    return regionalOfficeDropdowns;
  };

  render() {
    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
      </Link>
      <SearchableDropdown
        name="ro"
        label="Regional Office"
        options={this.regionalOfficeOptions()}
        placeholder=""
      />
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.array
};