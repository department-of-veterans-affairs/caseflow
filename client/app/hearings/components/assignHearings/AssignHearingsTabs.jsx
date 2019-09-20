import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';
import PropTypes from 'prop-types';
import LEGACY_APPEAL_TYPES_BY_ID from '../../../../constants/LEGACY_APPEAL_TYPES_BY_ID.json';

import { sortHearings } from '../../utils';
import COPY from '../../../../COPY.json';
import AssignHearingsTable from './AssignHearingsTable';
import TabWindow from '../../../components/TabWindow';
import { renderAppealType } from '../../../queue/utils';
import StatusMessage from '../../../components/StatusMessage';
import { getFacilityType } from '../../../components/DataDropdowns/AppealHearingLocations';
import { getIndexOfDocketLine, docketCutoffLineStyle } from './AssignHearingsDocketLine';
import { HearingTime, HearingDocketTag, AppealDocketTag,
  SuggestedHearingLocation, HearingAppellantName, CaseDetailsInformation } from './AssignHearingsFields';

import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG.json';

const NoUpcomingHearingDayMessage = () => (
  <StatusMessage
    title={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_HEADER}
    type="alert"
    messageText={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_MESSAGE}
    wrapInAppSegment={false}
  />
);

const AvailableVeteransTable = ({ rows, columns, selectedHearingDay, tabName, style = {} }) => {
  let removeTimeColumn = _.slice(columns, 0, -1);

  if (_.isNil(selectedHearingDay)) {
    return <div><NoUpcomingHearingDayMessage /></div>;
  }

  // if (_.isEmpty(rows)) {
  //   return <div>
  //     <StatusMessage
  //       title= {COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_HEADER}
  //       type="alert"
  //       messageText={COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_MESSAGE}
  //       wrapInAppSegment={false}
  //     />
  //   </div>;
  // }

  return <span {...style}>
    <AssignHearingsTable columns={removeTimeColumn} rowObjects={rows} tabName={tabName} enablePagination />
  </span>;
};

AvailableVeteransTable.propTypes = {
  rows: PropTypes.array,
  columns: PropTypes.array,
  style: PropTypes.object,
  tabName: PropTypes.string,
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string
  })
};

const UpcomingHearingsTable = ({ rows, columns, selectedHearingDay }) => {
  if (_.isNil(selectedHearingDay)) {
    return <div><NoUpcomingHearingDayMessage /></div>;
  }

  return <div>
    <Link to={`/schedule/docket/${selectedHearingDay.id}`}>
      {`View the Daily Docket for ${moment(selectedHearingDay.scheduledFor).format('M/DD/YYYY')}` }
    </Link>
    <AssignHearingsTable columns={columns} rowObjects={rows} tabName={QUEUE_CONFIG.UPCOMING_HEARINGS_TAB_NAME} />
  </div>;
};

UpcomingHearingsTable.propTypes = {
  rows: PropTypes.array,
  columns: PropTypes.array,
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string
  })
};

export default class AssignHearingsTabs extends React.Component {

  isAmaAppeal = (appeal) => {
    return appeal.attributes.appealType === 'Appeal';
  };

  isCentralOffice = () => {
    return this.props.selectedRegionalOffice === 'C';
  }

  getSuggestedHearingLocation = (locations) => {
    if (!locations || locations.length === 0) {
      return '';
    }

    /* Sort available locations before selecting top one. */
    const sortedLocations = _.orderBy(locations, ['distance'], ['asc']);

    /* Select first entry which should be shortest distance. */
    const location = sortedLocations[0];

    return location;
  };

  formatSuggestedHearingLocation = (suggestedLocation) => {
    if (_.isNull(suggestedLocation) || _.isUndefined(suggestedLocation)) {
      return null;
    }

    const { city, state } = suggestedLocation;

    return `${city}, ${state} ${getFacilityType(location)}`;
  }

  availableVeteransRows = (appeals) => {

    /*
      Sorting by docket number within each category of appeal:
      CAVC, AOD and normal. Prepended * and + to docket number for
      CAVC and AOD to group them first and second.
     */

    const sortedByAodCavc = _.sortBy(appeals, (appeal) => {
      if (appeal.attributes.caseType === LEGACY_APPEAL_TYPES_BY_ID.cavc_remand) {
        return `*${appeal.attributes.docketNumber}`;
      } else if (appeal.attributes.aod) {
        return `+${appeal.attributes.docketNumber}`;
      }

      return appeal.attributes.docketNumber;
    });

    return _.map(sortedByAodCavc, (appeal, index) => ({
      number: <span>{index + 1}.</span>,
      caseDetails: <CaseDetailsInformation appeal={appeal.attributes} />,
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: <AppealDocketTag appeal={appeal} />,
      suggestedLocation: this.getSuggestedHearingLocation(appeal.attributes.availableHearingLocations),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  upcomingHearingsRows = (hearings) => {
    return _.map(hearings, (hearing, index) => ({
      number: <span>{index + 1}.</span>,
      externalId: hearing.appealExternalId,
      caseDetails: <HearingAppellantName hearing={hearing} />,
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: <HearingDocketTag hearing={hearing} />,
      hearingLocation: hearing.readableLocation,
      time: <HearingTime hearing={hearing} isCentralOffice={this.isCentralOffice()} />
    }));
  };

  tabWindowColumns = (tab) => {
    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    if (_.isNil(selectedHearingDay)) {
      return [];
    }

    let locationColumn;

    if (tab === QUEUE_CONFIG.UPCOMING_HEARINGS_TAB_NAME) {
      locationColumn = {
        name: 'Hearing Location',
        header: 'Hearing Location',
        align: 'left',
        columnName: 'hearingLocation',
        valueName: 'hearingLocation',
        label: 'Filter by location',
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      };
    } else {
      locationColumn = {
        name: 'Suggested Location',
        header: 'Suggested Location',
        align: 'left',
        columnName: 'suggestedLocation',
        valueFunction: (task) => <SuggestedHearingLocation
          suggestedLocation={task.appeal.availableHearingLocations[0]}
          format={this.formatSuggestedHearingLocation} />,
        label: 'Filter by location',
        filterValueTransform: this.formatSuggestedHearingLocation,
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      };
    }

    return [{
      header: '',
      align: 'left',
      valueName: 'number'
    },
    {
      header: 'Case details',
      align: 'left',
      valueName: QUEUE_CONFIG.CASE_DETAILS_LINK_COLUMN,
      valueFunction: (task) => <Link
        name={task.externalAppealId}
        href={(() => {
          const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
          const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}`;

          return `/queue/appeals/${task.externalAppealId}/${qry}`;
        })()}>
        <CaseDetailsInformation appeal={task.appeal} />
      </Link>
    },
    {
      header: 'Type(s)',
      align: 'left',
      valueName: 'type',
      valueFunction: (task) => renderAppealType({
        caseType: task && task.appeal && task.appeal.caseType,
        isAdvancedOnDocket: task && task.appeal && task.appeal.aod
      })
    },
    {
      header: 'Docket number',
      align: 'left',
      valueName: 'docketNumber',
      valueFunction: (task) => <AppealDocketTag appeal={task.appeal} />
    },
    locationColumn,
    {
      header: 'Time',
      align: 'left',
      valueName: 'time'
    }];
  }

  amaDocketCutoffLineStyle = (appeals) => {
    const endOfNextMonth = moment().add('months', 1).
      endOf('month');
    const indexOfLine = getIndexOfDocketLine(appeals, endOfNextMonth);

    return docketCutoffLineStyle(indexOfLine, endOfNextMonth.format('MMMM YYYY'));
  }

  render() {
    const { selectedHearingDay, appealsReadyForHearing, room } = this.props;

    const hearingsForSelected = _.get(selectedHearingDay, 'hearings', []);
    const availableSlots = _.get(selectedHearingDay, 'totalSlots', 0) - Object.keys(hearingsForSelected).length;

    const upcomingRows = this.upcomingHearingsRows(sortHearings(hearingsForSelected));
    const amaAppeals = _.filter(appealsReadyForHearing, (appeal) => this.isAmaAppeal(appeal));
    const amaRows = this.availableVeteransRows(amaAppeals);
    const legacyRows = this.availableVeteransRows(
      _.filter(appealsReadyForHearing, (appeal) => !this.isAmaAppeal(appeal))
    );

    return <div className="usa-width-three-fourths">
      {!_.isNil(selectedHearingDay) && <h1>
        {`${moment(selectedHearingDay.scheduledFor).format('ddd M/DD/YYYY')}
          ${room} (${availableSlots} slots remaining)`}
      </h1>}
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled Veterans',
            page: <UpcomingHearingsTable
              selectedHearingDay={selectedHearingDay}
              rows={upcomingRows}
              columns={this.tabWindowColumns(QUEUE_CONFIG.UPCOMING_HEARINGS_TAB_NAME)}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              rows={legacyRows}
              columns={this.tabWindowColumns(QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME)}
              selectedHearingDay={selectedHearingDay}
              tabName={QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              style={this.amaDocketCutoffLineStyle(amaAppeals)}
              rows={amaRows}
              columns={this.tabWindowColumns(QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME)}
              selectedHearingDay={selectedHearingDay}
              tabName={QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}
            />
          }
        ]}
      />
    </div>;
  }
}

const appealPropTypes = PropTypes.shape({
  attributes: PropTypes.shape({
    caseType: PropTypes.string,
    docketNumber: PropTypes.string,
    aod: PropTypes.bool,
    availableHearingLocations: PropTypes.array,
    externalAppealId: PropTypes.string
  })
});

AssignHearingsTabs.propTypes = {
  appealsReadyForHearing: PropTypes.arrayOf(appealPropTypes),
  selectedHearingDay: PropTypes.shape({
    hearings: PropTypes.object,
    id: PropTypes.number,
    regionalOffice: PropTypes.string,
    regionalOfficeKey: PropTypes.string,
    requestType: PropTypes.string,
    room: PropTypes.string,
    scheduledFor: PropTypes.string,
    totalSlots: PropTypes.number
  }),
  selectedRegionalOffice: PropTypes.string,
  room: PropTypes.string
};
