import React from 'react';
import { connect } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';
import PropTypes from 'prop-types';
import LEGACY_APPEAL_TYPES_BY_ID from '../../../../constants/LEGACY_APPEAL_TYPES_BY_ID';

import COPY from '../../../../COPY';
import AssignHearingsTable from './AssignHearingsTable';
import UpcomingHearingsTable from './UpcomingHearingsTable';
import TabWindow from '../../../components/TabWindow';
import { renderAppealType } from '../../../queue/utils';
import StatusMessage from '../../../components/StatusMessage';
import { getFacilityType } from '../../../components/DataDropdowns/AppealHearingLocations';
import { NoUpcomingHearingDayMessage } from './Messages';
import { getIndexOfDocketLine, docketCutoffLineStyle } from './AssignHearingsDocketLine';
import { AppealDocketTag, SuggestedHearingLocation, CaseDetailsInformation } from './AssignHearingsFields';
import PowerOfAttorneyDetail from '../../../queue/PowerOfAttorneyDetail';

const AvailableVeteransTable = ({ rows, columns, selectedHearingDay, style = {} }) => {
  if (_.isNil(selectedHearingDay)) {
    return <NoUpcomingHearingDayMessage />;
  }

  if (_.isEmpty(rows)) {
    return <div>
      <StatusMessage
        title= {COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_HEADER}
        type="alert"
        messageText={COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_MESSAGE}
        wrapInAppSegment={false}
      />
    </div>;
  }

  return <span {...style}>
    <AssignHearingsTable columns={columns} rowObjects={rows} />
  </span>;
};

AvailableVeteransTable.propTypes = {
  rows: PropTypes.array,
  columns: PropTypes.array,
  style: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string
  })
};

export class AssignHearingsTabs extends React.Component {

  isAmaAppeal = (appeal) => {
    return appeal.attributes.appealType === 'Appeal';
  };

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
      caseDetails: <CaseDetailsInformation appeal={appeal} />,
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: <AppealDocketTag appeal={appeal} />,
      suggestedLocation: this.getSuggestedHearingLocation(appeal.attributes.availableHearingLocations),
      externalId: appeal.attributes.externalAppealId,
      // The powerOfAttorney field is populated using the appeal's external id.
      powerOfAttorney: appeal.attributes.externalAppealId
    }));
  };

  tabWindowColumns = () => {
    // Remove `displayPowerOfAttorneyColumn` when pagination lands (#11757)
    const { selectedRegionalOffice, selectedHearingDay, displayPowerOfAttorneyColumn } = this.props;

    if (_.isNil(selectedHearingDay)) {
      return [];
    }

    const columns = [
      {
        header: '',
        align: 'left',
        valueName: 'number'
      },
      {
        header: 'Case Details',
        align: 'left',
        valueName: 'caseDetails',
        valueFunction: (row) => <Link
          name={row.externalId}
          href={(() => {
            const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
            const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}`;

            return `/queue/appeals/${row.externalId}/${qry}`;
          })()}>
          {row.caseDetails}
        </Link>
      },
      {
        header: 'Type(s)',
        align: 'left',
        valueName: 'type'
      },
      {
        header: 'Docket Number',
        align: 'left',
        valueName: 'docketNumber'
      },
      {
        name: 'Suggested Location',
        header: 'Suggested Location',
        align: 'left',
        columnName: 'suggestedLocation',
        valueFunction: (row) => (
          <SuggestedHearingLocation
            suggestedLocation={row.suggestedLocation}
            format={this.formatSuggestedHearingLocation}
          />
        ),
        label: 'Filter by location',
        filterValueTransform: this.formatSuggestedHearingLocation,
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      }
    ];

    // Put this in the `push` above when pagination lands (#11757)
    if (displayPowerOfAttorneyColumn) {
      columns.push(
        {
          name: 'Power of Attorney',
          header: 'Power of Attorney (POA)',
          columnName: 'powerOfAttorney',
          valueName: 'powerOfAttorney',
          valueFunction: (row) => (
            <PowerOfAttorneyDetail
              key={`poa-for-${row.externalId}`}
              appealId={row.externalId}
              displayNameOnly
            />
          ),
          enableFilter: true,
          filterValueTransform: (appealExternalId) => {
            const { powerOfAttorneyNamesForAppeals } = this.props;

            return powerOfAttorneyNamesForAppeals[appealExternalId];
          }
        }
      );
    }

    return columns;
  }

  amaDocketCutoffLineStyle = (appeals) => {
    const endOfNextMonth = moment().add('months', 1).
      endOf('month');
    const indexOfLine = getIndexOfDocketLine(appeals, endOfNextMonth);

    return docketCutoffLineStyle(indexOfLine, endOfNextMonth.format('MMMM YYYY'));
  }

  render() {
    const {
      selectedHearingDay,
      selectedRegionalOffice,
      appealsReadyForHearing,
      room
    } = this.props;

    const hearingsForSelected = _.get(selectedHearingDay, 'hearings', {});
    const availableSlots = _.get(selectedHearingDay, 'totalSlots', 0) - Object.keys(hearingsForSelected).length;

    const amaAppeals = _.filter(appealsReadyForHearing, (appeal) => this.isAmaAppeal(appeal));
    const amaRows = this.availableVeteransRows(amaAppeals);
    const legacyRows = this.availableVeteransRows(
      _.filter(appealsReadyForHearing, (appeal) => !this.isAmaAppeal(appeal))
    );

    // Remove when pagination lands (#11757)
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
              selectRegionalOffice={selectedRegionalOffice}
              selectedHearingDay={selectedHearingDay}
              hearings={hearingsForSelected}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              rows={legacyRows}
              columns={this.tabWindowColumns()}
              selectedHearingDay={selectedHearingDay}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              style={this.amaDocketCutoffLineStyle(amaAppeals)}
              rows={amaRows}
              columns={this.tabWindowColumns()}
              selectedHearingDay={selectedHearingDay}
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
  appealsReadyForHearing: PropTypes.oneOfType([
    PropTypes.arrayOf(appealPropTypes),
    PropTypes.object
  ]),
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
  room: PropTypes.string,
  // Appeal ID => Attorney Name Array
  powerOfAttorneyNamesForAppeals: PropTypes.objectOf(PropTypes.string),
  // Remove when pagination lands (#11757)
  displayPowerOfAttorneyColumn: PropTypes.bool
};

AssignHearingsTabs.defaultProps = {
  powerOfAttorneyNamesForAppeals: {}
};

const mapStateToProps = (state) => {
  const powerOfAttorneyNamesForAppeals = _.mapValues(
    _.get(state, 'queue.appealDetails', {}),
    (val) => _.get(val, 'powerOfAttorney.representative_name')
  );

  return { powerOfAttorneyNamesForAppeals };
};

export default connect(mapStateToProps)(AssignHearingsTabs);
