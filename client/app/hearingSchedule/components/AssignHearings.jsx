import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import Table from '../../components/Table';
import { css } from 'glamor';
import moment from 'moment';
import { COLORS } from '../../constants/AppConstants';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import { renderAppealType } from '../../queue/utils';
import StatusMessage from '../../components/StatusMessage';

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const roSelectionStyling = css({ marginTop: '10px' });

export default class AssignHearings extends React.Component {

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

  };

  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth" {...roSelectionStyling}>
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {_.orderBy(Object.values(this.props.upcomingHearingDays), (hearingDay) => hearingDay.hearingDate, 'asc').
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

            const styling = dateSelected ? buttonColorSelected : {};

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

  getHearingTime = (date, regionalOfficeTimezone) => {

    if (this.props.selectedRegionalOffice.label === 'Central') {
      return <div>{getTime(date)} </div>;
    }

    return <div>
      {getTime(date)} /<br />{getTimeInDifferentTimeZone(date, regionalOfficeTimezone)}
    </div>;
  };

  appellantName = (hearingDay) => {
    let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName, vbmsId } = hearingDay;

    if (appellantFirstName && appellantLastName) {
      return `${appellantFirstName} ${appellantLastName} | ${vbmsId}`;
    } else if (veteranFirstName && veteranLastName) {
      return `${veteranFirstName} ${veteranLastName} | ${vbmsId}`;
    }

    return `${vbmsId}`;

  };

  tableAssignHearingsRows = (veterans) => {
    return _.map(veterans, (veteran) => ({
      caseDetails: this.appellantName(veteran),
      type: renderAppealType({
        caseType: veteran.type,
        isAdvancedOnDocket: veteran.aod
      }),
      docketNumber: veteran.docketNumber,
      location: this.props.selectedRegionalOffice.value === 'C' ? 'Washington DC' : veteran.location,
      time: veteran.time,
      vacolsId: veteran.vacolsId,
      appealId: veteran.appealId
    }));
  };

  tableScheduledHearingsRows = (hearings) => {
    return _.map(hearings, (hearing) => ({
      vacolsId: hearing.appealVacolsId,
      caseDetails: `${hearing.appellantMiFormatted || hearing.veteranMiFormatted} | ${hearing.vbmsId}`,
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: hearing.docketNumber,
      location: hearing.readableLocation,
      time: this.getHearingTime(hearing.date, hearing.regionalOfficeTimezone)
    }));
  };

  veteransReadyForHearing = () => {

    const { selectedHearingDay, selectedRegionalOffice } = this.props;
    const date = moment(selectedHearingDay.hearingDate).format('YYYY-MM-DD');
    const time = getTime(selectedHearingDay.hearingDate);
    const SROVal = selectedRegionalOffice.value;
    const qry = `?hearingDate=${date}&regionalOffice=${SROVal}&hearingTime=${time}`;

    const tabWindowColumns = [
      {
        header: 'Case details',
        align: 'left',
        valueName: 'caseDetails',
        valueFunction: (veteran) => <Link
          href={`/queue/appeals/${veteran.vacolsId}/${qry}`}
          name={veteran.vacolsId}>
          {veteran.caseDetails}
        </Link>
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
    const veteranNotAssignedTitle = <span {...veteranNotAssignedTitleStyle}>There are no schedulable veterans</span>;

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
        slowReRendersAreOk
      />;

    };

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;
    const scheduledOrder = _.sortBy(
      (this.props.selectedHearingDay.hearings), 'date');

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
              rowObjects={this.tableScheduledHearingsRows(scheduledOrder)}
              summary="scheduled-hearings-table"
              slowReRendersAreOk
            />
          },
          {
            label: 'Schedule a Veteran',
            page: scheduleableVeterans()
          }
        ]}
      />
    </div>;
  };

  render() {
    const hasUpcomingHearingDays = !_.isEmpty(this.props.upcomingHearingDays);

    return (
      <React.Fragment>
        {hasUpcomingHearingDays && this.formatAvailableHearingDays()}
        {hasUpcomingHearingDays &&
          this.props.veteransReadyForHearing &&
          this.props.selectedHearingDay &&
          this.veteransReadyForHearing()}
      </React.Fragment>
    );
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  selectedRegionalOffice: PropTypes.object,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.object,
  veteransReadyForHearing: PropTypes.object,
  userId: PropTypes.number,
  onReceiveTasks: PropTypes.func
};
