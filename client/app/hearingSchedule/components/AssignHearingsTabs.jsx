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

const filterDropdownFix = css({
  '& svg.table-icon + div': {
    position: 'absolute !important',
    padding: '10px',
    border: '1px solid #ddd',
    background: '#fff',
    cursor: 'pointer'
  }
});

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

  constructor(props) {
    super(props);

    this.state = {
      amaAppeals: {
        dropdownIsOpen: false,
        filteredBy: []
      },
      legacyAppeals: {
        dropdownIsOpen: false,
        filteredBy: []
      },
      upcomingHearings: {
        dropdownIsOpen: false,
        filteredBy: []
      }
    };
  }

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

  getLocationType = (location) => {
    const { facilityType, classification } = location;

    switch (facilityType) {
    case 'vet_center':
      return '(Vet Center)';
    case 'health':
      return '(VHA)';
    case 'benefits':
      return classification.indexOf('Regional') === -1 ? '(VBA)' : '(RO)';
    default:
      return '';
    }
  }

  getSuggestedHearingLocation = (location) => {
    if (!location) {
      return '';
    }

    const { city, state, distance } = location;

    return <span>
      <div>{`${city}, ${state} ${this.getLocationType(location)}`}</div>
      <div>{`Distance: ${distance} miles away`}</div>
    </span>;
  }

  availableVeteransRows = (appeals, { tab }) => {
    const filteredBy = this.state[tab].filteredBy;
    const filtered = _.filter(appeals, (appeal) => {

      if (filteredBy.length === 0) {
        return true;
      }

      if (appeal.attributes.suggestedHearingLocation === null && filteredBy.indexOf('null') !== -1) {
        return true;
      }

      return filteredBy.indexOf(appeal.attributes.suggestedHearingLocation.facilityId) !== -1;
    });

    return _.map(filtered, (appeal) => ({
      caseDetails: this.getCaseDetailsInformation(appeal),
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: this.getAppealDocketTag(appeal),
      suggestedLocation: this.getSuggestedHearingLocation(appeal.attributes.suggestedHearingLocation),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  upcomingHearingsRows = (hearings) => {
    const filteredBy = this.state.upcomingHearings.filteredBy;
    const filtered = _.filter(hearings, (hearing) => {

      if (filteredBy.length === 0) {
        return true;
      }

      if (hearing.location === null && filteredBy.indexOf('null') !== -1) {
        return true;
      }

      return filteredBy.indexOf(hearing.location.facilityId) !== -1;
    });

    return _.map(filtered, (hearing) => ({
      externalId: hearing.appealExternalId,
      caseDetails: this.appellantName(hearing),
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: this.getHearingDocketTag(hearing),
      suggestedLocation: this.getSuggestedHearingLocation(hearing.location),
      time: this.getHearingTime(hearing.scheduledFor, hearing.regionalOfficeTimezone)
    }));
  };

  getLocationFilterValues = (data, tab) => {
    const getLocation = (row) => tab === 'upcomingHearings' ? row.location : row.attributes.suggestedHearingLocation;

    const locations = data.map((row) => {
      const location = getLocation(row);

      if (!location) {
        return {
          displayText: '<<blank>>',
          value: 'null'
        };
      }

      const { city, state, facilityId } = location;

      return {
        displayText: `${city}, ${state}`,
        value: facilityId || 'null'
      };
    });

    const countByValue = _.countBy(locations, 'value');

    return _.sortedUniqBy(locations, 'value').map((row) => ({
      ...row,
      displayText: `${row.displayText} (${countByValue[row.value]} Veterans)`
    }));
  }

  tabWindowColumns = (data, { tab }) => {

    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    const state = this.state[tab];
    let locationFilterValues = this.getLocationFilterValues(data, tab);

    locationFilterValues.unshift({
      displayText: `All (${data.length})`,
      value: 'all'
    });

    return [{
      header: 'Case details',
      align: 'left',
      valueName: 'caseDetails',
      valueFunction: (appeal) => <Link
        name={appeal.externalId}
        href={(() => {
          const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
          const timer = () => {
            let time = getTime(selectedHearingDay.scheduledFor);

            return time === '12:00 am ET' ? '' : time;
          };
          const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}&hearingTime=${timer()}`;

          return `/queue/appeals/${appeal.externalId}/${qry}`;
        })()}>
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
      valueName: 'suggestedLocation',
      getFilterValues: locationFilterValues,
      isDropdownFilterOpen: state.dropdownIsOpen,
      label: 'Filter by location',
      anyFiltersAreSet: true,
      toggleDropdownFilterVisiblity: () => this.setState({
        [tab]: {
          ...state,
          dropdownIsOpen: !state.dropdownIsOpen
        }
      }),
      setSelectedValue: (val) => {
        let filteredBy;

        if (val === 'all') {
          filteredBy = [];
        } else if (state.filteredBy.indexOf(val) === -1) {
          filteredBy = [...state.filteredBy, val];
        } else {
          filteredBy = _.remove([...state.filteredBy], (value) => value === val);
        }

        this.setState({
          [tab]: {
            ...state,
            filteredBy
          }
        });
      }
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

    const upcomingHearings = _.sortBy(selectedHearingDay.hearings, 'date');
    const amaAppeals = _.filter(appealsReadyForHearing, (appeal) => this.isAmaAppeal(appeal));
    const legacyAppeals = _.filter(appealsReadyForHearing, (appeal) => !this.isAmaAppeal(appeal));

    return <div className="usa-width-three-fourths" {...filterDropdownFix}>
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
              columns={this.tabWindowColumns(upcomingHearings, { tab: 'upcomingHearings' })}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              rows={this.availableVeteransRows(legacyAppeals, { tab: 'legacyAppeals' })}
              columns={this.tabWindowColumns(legacyAppeals, { tab: 'legacyAppeals' })}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              rows={this.availableVeteransRows(amaAppeals, { tab: 'amaAppeals' })}
              columns={this.tabWindowColumns(amaAppeals, { tab: 'amaAppeals' })}
            />
          }
        ]}
      />
    </div>;
  }
}
