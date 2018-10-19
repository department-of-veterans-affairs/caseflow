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
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import StatusMessage from '../../components/StatusMessage';

const colorAOD = css({
  color: 'red'
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const smallTopMargin = css({
  fontStyle: 'italic',
  '.usa-input-error': {
    marginTop: '1rem'
  },
  '.usa-input-error-message': {
    paddingBottom: '0',
    paddingTop: '0',
    right: '0'
  },
  '& > p': {
    fontWeight: '500',
    color: COLORS.RED_DARK,
    marginBottom: '0',
    fontSize: '1.7rem',
    marginTop: '1px'
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

    if (this.props.selectedRegionalOffice.label === 'St. Petersburg, FL') {
      return room;
    } else if (this.props.selectedRegionalOffice.label === 'Winston-Salem, NC') {
      return room;
    }

    return room = '';

  }

  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth">
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {Object.values(this.props.upcomingHearingDays).slice(0, 9).
          map((hearingDay) => {
            const { selectedHearingDay } = this.props;
            const dateSelected = selectedHearingDay &&
            (selectedHearingDay.hearingDate === hearingDay.hearingDate &&
               selectedHearingDay.roomInfo === hearingDay.roomInfo);
            const buttonColorSelected = css({
              backgroundColor: COLORS.GREY_DARK,
              color: COLORS.WHITE,
              borderRadius: '0.1rem 0.1rem 0 0',
              '&:hover': {
                backgroundColor: COLORS.GREY_DARK,
                color: COLORS.WHITE
              }
            });

            const styling = dateSelected ? buttonColorSelected : '';

            return <li key={hearingDay.id} >
              <Button
                styling={styling}
                onClick={this.onSelectedHearingDayChange(hearingDay)}
                linkStyling
              >
                {`${moment(hearingDay.hearingDate).format('ddd M/DD/YYYY')}
                ${this.roomInfo(hearingDay)}`}
              </Button>
            </li>;
          })}
      </ul>
    </div>;
  };

  veteranTypeColor = (docketType) => {

    if (docketType === 'CAVC') {
      return <span {...colorAOD}>CAVC</span>;
    } else if (docketType === 'AOD') {
      return <span {...colorAOD}>AOD</span>;
    }

    return docketType;
  }

    getHearingTime = (date, regionalOfficeTimezone) => {
      return <div>
        {getTime(date)} /<br />{getTimeInDifferentTimeZone(date, regionalOfficeTimezone)}
      </div>;
    };

  appellantName = (hearingDay) => {
    if (hearingDay.appellantFirstName && hearingDay.appellantLastName) {
      return `${hearingDay.appellantFirstName} ${hearingDay.appellantLastName} | ${hearingDay.id}`;
    }

    return `${hearingDay.id}`;

  }

  getNoUpcomingError = () => {
    if (this.props.selectedRegionalOffice) {
      return <div className="usa-input-error-message usa-input-error" {...smallTopMargin}>
        <span>{this.props.selectedRegionalOffice && this.props.selectedRegionalOffice.label} has
          no upcoming hearing days.</span><br />
        <p>Please verify that this RO's hearing days are in the current schedule.</p>
      </div>;
    }
  }

  tableAssignHearingsRows = (veterans) => {
    return _.map(veterans, (veteran) => ({
      caseDetails: this.appellantName(veteran),
      type: this.veteranTypeColor(veteran.type),
      docketNumber: veteran.docketNumber,
      location: this.props.selectedRegionalOffice.value === 'C' ? 'Washington DC' : veteran.location,
      time: null
    }));
  };

  tableScheduledHearingsRows = (hearings) => {
    return _.map(hearings, (hearing) => ({
      caseDetails: `${hearing.appellantMiFormatted} | ${hearing.vbmsId}`,
      type: this.veteranTypeColor(hearing.appealType),
      docketNumber: hearing.docketNumber,
      location: hearing.requestType === 'Video' ? hearing.regionalOfficeName : 'Washington DC',
      time: this.getHearingTime(hearing.date, hearing.regionalOfficeTimezone)
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

    const veteranNotAssignedStyle = css({ fontSize: '3rem' });
    const veteranNotAssignedMessage = <span {...veteranNotAssignedStyle}>
      Please verify that this RO has veterans to assign a hearing</span>;
    const veteranNotAssignedTitleStyle = css({ fontSize: '4rem' });
    const veteranNotAssignedTitle = <span {...veteranNotAssignedTitleStyle}>There are no scheduleable veterans</span>;

    const scheduleableVeterans = () => {
      if (_.isEmpty(this.props.veteransReadyForHearing)) {
        return <div>
          <StatusMessage
            title= {veteranNotAssignedTitle}
            type="alert"
            messageText={veteranNotAssignedMessage}
            wrapInAppSegment={false}
          />
        </div>;
      }

      return <Table
        columns={tabWindowColumns}
        rowObjects={this.tableAssignHearingsRows(this.props.veteransReadyForHearing)}
        summary="scheduled-hearings-table"
      />;

    };

    const selectedHearingDay = this.props.selectedHearingDay;

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;

    return <div className="usa-width-three-fourths">
      <h1>
        {`${moment(selectedHearingDay.hearingDate).format('ddd M/DD/YYYY')}
       ${this.roomInfo(selectedHearingDay)} (${availableSlots} slots remaining)`}
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableScheduledHearingsRows(this.props.selectedHearingDay.hearings)}
              summary="scheduled-hearings-table"
            />
          },
          {
            label: 'Assign Hearings',
            page: scheduleableVeterans()
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
      <div>{_.isEmpty(this.props.upcomingHearingDays) && this.getNoUpcomingError()}</div>
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
