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
import DocketTypeBadge from '../../components/DocketTypeBadge';

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const roSelectionStyling = css({ marginTop: '10px' });

export default class AssignHearings extends React.Component {

  amaAppeal = (appeal) => {
    return appeal.attributes.appealType === 'Appeal';
  };

  getAmaAppeals = () => _.filter(this.props.appealsReadyForHearing, (appeal) => this.amaAppeal(appeal));

  getLegacyAppeals = () => _.filter(this.props.appealsReadyForHearing, (appeal) => !this.amaAppeal(appeal));

  onSelectedHearingDayChange = (hearingDay) => () => {
    this.props.onSelectedHearingDayChange(hearingDay);
  };

  room = (hearingDay) => {
    if (this.props.selectedRegionalOffice.label === 'St. Petersburg, FL') {
      return hearingDay.room;
    } else if (this.props.selectedRegionalOffice.label === 'Winston-Salem, NC') {
      return hearingDay.room;
    }

    return '';
  };

  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth" {...roSelectionStyling}>
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {_.orderBy(Object.values(this.props.upcomingHearingDays), (hearingDay) => hearingDay.scheduledFor, 'asc').
          map((hearingDay) => {
            const { selectedHearingDay } = this.props;
            const dateSelected = selectedHearingDay &&
            (selectedHearingDay.scheduledFor === hearingDay.scheduledFor &&
               selectedHearingDay.room === hearingDay.room);
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
                {`${moment(hearingDay.scheduledFor).format('ddd M/DD/YYYY')}
                ${this.room(hearingDay)}`}
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
    let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName, veteranFileNumber } = hearingDay;

    if (appellantFirstName && appellantLastName) {
      return `${appellantFirstName} ${appellantLastName} | ${veteranFileNumber}`;
    } else if (veteranFirstName && veteranLastName) {
      return `${veteranFirstName} ${veteranLastName} | ${veteranFileNumber}`;
    }

    return `${veteranFileNumber}`;
  };

  getAppealLocation = (appeal) => {
    if (this.props.selectedRegionalOffice.value === 'C') {
      return 'Washington DC';
    }

    if (!appeal.attributes.regionalOffice) {
      return null;
    }

    return `${appeal.attributes.regionalOffice.city}, ${appeal.attributes.regionalOffice.state}`;
  };

  getCaseDetailsInformation = (appeal) => {
    if (appeal.attributes.appellantFullName) {
      return `${appeal.attributes.appellantFullName} | ${appeal.attributes.veteranFileNumber}`;
    }

    return `${appeal.attributes.veteranFullName} | ${appeal.attributes.veteranFileNumber}`;
  };

  getHearingDocketTag = (hearing) => {
    if (hearing.docketNumber) {
      return <div>
        <DocketTypeBadge name={hearing.docketName} number={hearing.docketNumber} />
        {hearing.docketNumber}
      </div>;
    }

  }

  getAppealDocketTag = (appeal) => {
    if (appeal.attributes.docketNumber) {
      return <div>
        <DocketTypeBadge name={appeal.attributes.docketName} number={appeal.attributes.docketNumber} />
        {appeal.attributes.docketNumber}
      </div>;
    }

  }

  tableAssignHearingsRows = (appeals) => {
    return _.map(appeals, (appeal) => ({
      caseDetails: this.getCaseDetailsInformation(appeal),
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: this.getAppealDocketTag(appeal),
      location: this.getAppealLocation(appeal),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  tableScheduledHearingsRows = (hearings) => {
    return _.map(hearings, (hearing) => ({
      externalId: hearing.appealVacolsId,
      caseDetails: this.appellantName(hearing),
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: this.getHearingDocketTag(hearing),
      location: hearing.readableLocation,
      time: this.getHearingTime(hearing.scheduledFor, hearing.regionalOfficeTimezone)
    }));
  };

  appealsReadyForHearing = () => {

    const { selectedHearingDay, selectedRegionalOffice } = this.props;
    const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
    const SROVal = selectedRegionalOffice.value;
    const timer = () => {
      let time = getTime(selectedHearingDay.scheduledFor);

      if (time === '12:00 am ET') {
        return '';

      }

      return time;
    };

    const qry = `?hearingDate=${date}&regionalOffice=${SROVal}&hearingTime=${timer()}`;

    const tabWindowColumns = [
      {
        header: 'Case details',
        align: 'left',
        valueName: 'caseDetails',
        valueFunction: (appeal) => <Link
          href={`/queue/appeals/${appeal.externalId}/${qry}`}
          name={appeal.externalId}>
          {appeal.caseDetails}
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

    const scheduleableLegacyVeterans = () => {
      if (_.isEmpty(this.getLegacyAppeals())) {
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
        rowObjects={this.tableAssignHearingsRows(this.getLegacyAppeals())}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
      />;
    };

    const scheduleableAmaVeterans = () => {
      if (_.isEmpty(this.getAmaAppeals())) {
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
        rowObjects={this.tableAssignHearingsRows(this.getAmaAppeals())}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
      />;
    };

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;
    const scheduledOrder = _.sortBy(
      (this.props.selectedHearingDay.hearings), 'date');

    return <div className="usa-width-three-fourths">
      <h1>
        {`${moment(selectedHearingDay.scheduledFor).format('ddd M/DD/YYYY')}
       ${this.room(selectedHearingDay)} (${availableSlots} slots remaining)`}
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled Veterans',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableScheduledHearingsRows(scheduledOrder)}
              summary="scheduled-hearings-table"
              slowReRendersAreOk
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: scheduleableLegacyVeterans()
          },
          {
            label: 'AMA Veterans Waiting',
            page: scheduleableAmaVeterans()
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
          this.props.appealsReadyForHearing &&
          this.props.selectedHearingDay &&
          this.appealsReadyForHearing()}
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
  appealsReadyForHearing: PropTypes.object,
  userId: PropTypes.number,
  onReceiveTasks: PropTypes.func
};
