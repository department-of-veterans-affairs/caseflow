import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import Table from '../../components/Table';
import RoSelectorDropdown from './RoSelectorDropdown';
import moment from 'moment';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';

const colorAOD = css({
  color: 'red'
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

const hoverColor = css({
  '&:hover': {
    backgroundColor: COLORS.GREY_DARK,
    color: COLORS.WHITE,
    border: 0
  }
});

export default class AssignHearings extends React.Component {

  // required to reset the RO Dropdown when moving from Viewing and Assigning.
  componentWillMount = () => {
    this.props.onRegionalOfficeChange('');
  }

  onSelectedHearingDayChange = (hearingDay) => () => {
    this.props.onSelectedHearingDayChange(hearingDay);
  };

  roomInfo = (hearingDay) => {
    let room = hearingDay.roomInfo;

    if (hearingDay.regionalOffice === 'St. Petersburg, FL') {
      return room;
    } else if (hearingDay.regionalOffice === 'Winston-Salem, NC') {
      return room;
    }

    return room = '';

  }
  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth">
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list">
        {Object.values(this.props.upcomingHearingDays).slice(0, 9).
          map((hearingDay) => {
            const availableSlots = hearingDay.totalSlots - Object.keys(hearingDay.hearings).length;

            return <li key={hearingDay.id} >
              <Button
                styling={hoverColor}
                onClick={this.onSelectedHearingDayChange(hearingDay)}
                linkStyling
              >
                {`${moment(hearingDay.hearingDate).format('ddd M/DD/YYYY')}
                ${this.roomInfo(hearingDay)} (${availableSlots} slots)`}
              </Button>
            </li>;
          })}
      </ul>
    </div>;
  };

  veteranTypeColor = (type) => {
    let veteranType;

    if (type === 'CAVC') {
      veteranType = <span {...colorAOD}>CAVC</span>;
    } else if (type === 'AOD') {
      veteranType = <span {...colorAOD}>AOD</span>;
    }

    return veteranType;
  }

  tableRows = (veterans) => {
    return _.map(veterans, (veteran) => ({
      caseDetails: veteran.name,
      type: this.veteranTypeColor(veteran.type),
      docketNumber: veteran.docketNumber,
      location: veteran.location,
      time: veteran.time
    }));
  };

  veteransReadyForHearing = () => {

    const tabWindowColumns = [
      {
        header: 'Case details',
        align: 'left',
        valueName: 'caseDetails'
      },
      {
        header: 'Type(s)',
        align: 'left',
        valueName: 'type'
      },
      {
        header: 'Docket number',
        align: 'left',
        valueName: 'docketNumber'
      },
      {
        header: 'Location',
        align: 'left',
        valueName: 'location'
      },
      {
        header: 'Time',
        align: 'left',
        valueName: 'time'
      }
    ];

    const selectedHearingDay = this.props.selectedHearingDay;

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;

    return <div className="usa-width-three-fourths">
      <h1>
        {moment(selectedHearingDay.hearingDate).format('ddd M/DD/YYYY')}
        {this.roomInfo(selectedHearingDay)} ({availableSlots} slots remaining)
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableRows(this.props.selectedHearingDay.hearings)}
              summary="scheduled-hearings-table"
            />
          },
          {
            label: 'Assign Hearings',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableRows(this.props.veteransReadyForHearing)}
              summary="assign-hearings-table"
            />
          }
        ]}
      />
    </div>;
  };

  render() {
    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
      </Link>
      <RoSelectorDropdown
        onChange={this.props.onRegionalOfficeChange}
        value={this.props.selectedRegionalOffice}
        staticOptions={centralOfficeStaticEntry}
      />
      {this.props.upcomingHearingDays && this.formatAvailableHearingDays()}
      {this.props.upcomingHearingDays &&
        this.props.veteransReadyForHearing &&
        this.props.selectedHearingDay &&
        this.veteransReadyForHearing()}
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  onRegionalOfficeChange: PropTypes.func,
  selectedRegionalOffice: PropTypes.object,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.object,
  veteransReadyForHearing: PropTypes.object
};
