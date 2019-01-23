import React from 'react';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';

import Table from '../../components/Table';
import TabWindow from '../../components/TabWindow';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { renderAppealType } from '../../queue/utils';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import StatusMessage from '../../components/StatusMessage';

const veteranNotAssignedStyle = css({ fontSize: '3rem' });
const veteranNotAssignedMessage = <span {...veteranNotAssignedStyle}>
  Please verify that this RO has veterans to assign a hearing</span>;
const veteranNotAssignedTitleStyle = css({ fontSize: '4rem' });
const veteranNotAssignedTitle = <span {...veteranNotAssignedTitleStyle}>There are no schedulable veterans</span>;

const AvailableVeteransTable = ({ rows, columns }) => {
  if (_.isEmpty(rows)) {
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
    columns={columns}
    rowObjects={rows}
    summary="scheduled-hearings-table"
    slowReRendersAreOk
  />;
};

const UpcomingHearingsTable = ({ rows, columns }) => (
  <Table
    columns={columns}
    rowObjects={rows}
    summary="scheduled-hearings-table"
    slowReRendersAreOk
  />
);

export default class AssignHearingsTabs extends React.Component {

  isAmaAppeal = (appeal) => {
    return appeal.attributes.appealType === 'Appeal';
  };

  getHearingTime = (date, regionalOfficeTimezone) => {

    if (this.props.selectedRegionalOffice === 'C') {
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
    if (this.props.selectedRegionalOffice === 'C') {
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

  getSuggestedHearingLocation = (appeal) => {
    if (!appeal.attributes.suggestedHearingLocation) {
      return '';
    }

    const { city, state, distance, facilityType } = appeal.attributes.suggestedHearingLocation;

    return <span>
      <div>{`${city}, ${state} (${facilityType})`}</div>
      <div>{`Distance: ${distance} miles away`}</div>
    </span>;
  }

  availableVeteransRows = (appeals) => {
    return _.map(appeals, (appeal) => ({
      caseDetails: this.getCaseDetailsInformation(appeal),
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: this.getAppealDocketTag(appeal),
      suggestLocation: this.getSuggestedHearingLocation(appeal),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  upcomingHearingsRows = (hearings) => {
    return _.map(hearings, (hearing) => ({
      externalId: hearing.appealExternalId,
      caseDetails: this.appellantName(hearing),
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: this.getHearingDocketTag(hearing),
      suggestedLocation: hearing.readableLocation,
      time: this.getHearingTime(hearing.scheduledFor, hearing.regionalOfficeTimezone)
    }));
  };

  tabWindowColumns = () => {

    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
    const timer = () => {
      let time = getTime(selectedHearingDay.scheduledFor);

      if (time === '12:00 am ET') {
        return '';
      }

      return time;
    };

    const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}&hearingTime=${timer()}`;

    return [{
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
      header: 'Suggested Location',
      align: 'left',
      valueName: 'suggestLocation'
    },
    {
      header: 'Time',
      align: 'left',
      valueName: 'time'
    }];
  }

  render() {
    const { selectedHearingDay, appealsReadyForHearing, room } = this.props;

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;

    const columns = this.tabWindowColumns();

    const upcomingHearings = _.sortBy(selectedHearingDay.hearings, 'date');
    const amaAppeals = _.filter(appealsReadyForHearing, (appeal) => this.isAmaAppeal(appeal));
    const legacyAppeals = _.filter(appealsReadyForHearing, (appeal) => !this.isAmaAppeal(appeal));

    return <div className="usa-width-three-fourths">
      <h1>
        {`${moment(selectedHearingDay.scheduledFor).format('ddd M/DD/YYYY')}
          ${room} (${availableSlots} slots remaining)`}
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled Veterans',
            page: <UpcomingHearingsTable
              rows={this.upcomingHearingsRows(upcomingHearings)}
              columns={columns}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              rows={this.availableVeteransRows(legacyAppeals)}
              columns={columns}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              rows={this.availableVeteransRows(amaAppeals)}
              columns={columns}
            />
          }
        ]}
      />
    </div>;
  }
}
