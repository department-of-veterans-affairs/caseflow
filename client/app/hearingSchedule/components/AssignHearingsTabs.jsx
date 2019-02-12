import React from 'react';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';
import LEGACY_APPEAL_TYPES_BY_ID from '../../../constants/LEGACY_APPEAL_TYPES_BY_ID.json';

import Table from '../../components/Table';
import TabWindow from '../../components/TabWindow';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { renderAppealType } from '../../queue/utils';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import StatusMessage from '../../components/StatusMessage';
import { getFacilityType } from '../../components/DataDropdowns/VeteranHearingLocations';

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

const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  },
  '& td:nth-child(2)': {
    paddingLeft: 0
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
    bodyStyling={tableNumberStyling}
  />;
};

const UpcomingHearingsTable = ({ rows, columns, selectedHearingDay }) => (
  <div>
    <Link to={`/schedule/docket/${selectedHearingDay.id}`}>
      {`View the Daily Docket for ${moment(selectedHearingDay.scheduledFor).format('M/DD/YYYY')}` }</Link>
    <Table
      columns={columns}
      rowObjects={rows}
      summary="scheduled-hearings-table"
      slowReRendersAreOk
      bodyStyling={tableNumberStyling}
    />
  </div>
);

export default class AssignHearingsTabs extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      amaAppeals: {
        dropdownIsOpen: false,
        filteredBy: null
      },
      legacyAppeals: {
        dropdownIsOpen: false,
        filteredBy: null
      },
      upcomingHearings: {
        dropdownIsOpen: false,
        filteredBy: null
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

  getSuggestedHearingLocation = (location) => {
    if (!location) {
      return '';
    }

    const { city, state, distance } = location;

    return <span>
      <div>{`${city}, ${state} ${getFacilityType(location)}`}</div>
      <div>{`Distance: ${distance} miles away`}</div>
    </span>;
  }

  availableVeteransRows = (appeals, { tab }) => {
    const filteredBy = this.state[tab].filteredBy;
    const filtered = _.filter(appeals, (appeal) => {

      if (filteredBy === null) {
        return true;
      }

      if (_.isEmpty(appeal.attributes.veteranAvailableHearingLocations) && filteredBy === 'null') {
        return true;
      } else if (_.isEmpty(appeal.attributes.veteranAvailableHearingLocations)) {
        return false;
      }

      return filteredBy === appeal.attributes.veteranAvailableHearingLocations[0].facilityId;
    });

    const sortedByAodCavc = _.sortBy(filtered, (appeal) => {
      if (appeal.attributes.caseType === LEGACY_APPEAL_TYPES_BY_ID.cavc_remand) {
        return 0;
      } else if (appeal.attributes.aod) {
        return 1;
      }

      return 2;
    });

    return _.map(sortedByAodCavc, (appeal, index) => ({
      number: <span>{index + 1}.</span>,
      caseDetails: this.getCaseDetailsInformation(appeal),
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: this.getAppealDocketTag(appeal),
      suggestedLocation: this.getSuggestedHearingLocation(
        (appeal.attributes.veteranAvailableHearingLocations || [])[0]
      ),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  upcomingHearingsRows = (hearings) => {
    const filteredBy = this.state.upcomingHearings.filteredBy;
    const filtered = _.filter(hearings, (hearing) => {

      if (filteredBy === null) {
        return true;
      }

      if (_.isEmpty(hearing.location) && filteredBy === 'null') {
        return true;
      } else if (_.isEmpty(hearing.location)) {
        return false;
      }

      return filteredBy === hearing.location.facilityId;
    });

    return _.map(filtered, (hearing, index) => ({
      number: <span>{index + 1}.</span>,
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
    const getLocation = (row) => tab === 'upcomingHearings' ? row.location :
      (row.attributes.veteranAvailableHearingLocations || [])[0];

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

    return _.uniqBy(_.sortBy(locations, 'displayText'), 'value').map((row) => ({
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
      header: '',
      align: 'left',
      valueName: 'number'
    },
    {
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
        this.setState({
          [tab]: {
            dropdownIsOpen: false,
            filteredBy: val === 'all' ? null : val
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

    const upcomingHearings = _.orderBy(Object.values(selectedHearingDay.hearings),
      (hearing) => hearing.scheduledFor, 'asc');
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
              selectedHearingDay={selectedHearingDay}
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
