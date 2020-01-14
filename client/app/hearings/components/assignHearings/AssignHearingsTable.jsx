import PropTypes from 'prop-types';
import React from 'react';

import querystring from 'querystring';

import {
  AppealDocketTag,
  CaseDetailsInformation,
  SuggestedHearingLocation,
} from './AssignHearingsFields';
import { NoVeteransToAssignMessage } from './Messages';
import {
  getFacilityType,
} from '../../../components/DataDropdowns/AppealHearingLocations';
import { renderAppealType } from '../../../queue/utils';
import { tableNumberStyling } from './styles';
import LinkToAppeal from './LinkToAppeal';
import PowerOfAttorneyDetail from '../../../queue/PowerOfAttorneyDetail';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG.json';
import QueueTable from '../../../queue/QueueTable';

const TASKS_ENDPOINT = '/hearings/schedule_hearing_tasks';
const FILTER_PARAM_KEY = `${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`;

export default class AssignHearingsTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      showNoVeteransToAssignError: false
    };
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

  /*
   * Gets the list of columns to populate the QueueTable with.
   */
  getColumns = () => {
    // Remove `displayPowerOfAttorneyColumn` when pagination lands (#11757)
    const { selectedRegionalOffice, selectedHearingDay, displayPowerOfAttorneyColumn } = this.props;

    if (_.isNil(selectedHearingDay)) {
      return [];
    }

    const columns = [
      {
        header: '',
        align: 'left',
        // Since this column isn't tied to anything in the input row, _value will
        // always be undefined.
        valueFunction: (_value, rowId) => <span>{rowId + 1}.</span>
      },
      {
        header: 'Case Details',
        align: 'left',
        valueFunction: (row) => (
          <LinkToAppeal
            appealExternalId={row.externalAppealId}
            hearingDay={selectedHearingDay}
            regionalOffice={selectedRegionalOffice}
          >
            <CaseDetailsInformation appeal={row.appeal} />
          </LinkToAppeal>
        )
      },
      {
        header: 'Type(s)',
        align: 'left',
        valueFunction: (row) => renderAppealType({
          caseType: row.appeal.caseType,
          isAdvancedOnDocket: row.appeal.isAdvancedOnDocket
        })
      },
      {
        header: 'Docket Number',
        align: 'left',
        valueFunction: (row) => (
          <AppealDocketTag appeal={row.appeal} />
        )
      },
      {
        name: 'Suggested Location',
        header: 'Suggested Location',
        align: 'left',
        columnName: 'suggestedLocation',
        valueFunction: (row) => (
          <SuggestedHearingLocation
            suggestedLocation={this.getSuggestedHearingLocation(row.availableHearingLocations)}
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
          valueFunction: (row) => (
            <PowerOfAttorneyDetail
              key={`poa-${row.externalAppealId}-detail`}
              appealId={row.externalAppealId}
              displayNameOnly
            />
          ),
          enableFilter: true,
          filterValueTransform: (_value, row) => {
            const { powerOfAttorneyNamesForAppeals } = this.props;

            return powerOfAttorneyNamesForAppeals[row.externalAppealId];
          }
        }
      );
    }

    return columns;
  }

  // Callback when the QueueTable receives tasks from the API. If there are no
  // tasks for the table to display at all (not just for the current page),
  // update this component to show an error.
  onPageLoaded = ({ total_task_count }) => {
    this.setState({ showNoVeteransToAssignError: total_task_count === 0 });
  }

  render = () => {
    const { columns, tabName, selectedRegionalOffice } = this.props;
    const qs = querystring.stringify({
      [QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM]: tabName,
      regional_office_key: selectedRegionalOffice
    });
    const tabPaginationOptions = {
      [QUEUE_CONFIG.PAGE_NAME_REQUEST_PARAM]: 1,
      onPageLoaded: this.onPageLoaded
    };

    if (this.state.showNoVeteransToAssignError) {
      return <NoVeteransToAssignMessage />;
    }

    return (
      <QueueTable
        columns={this.getColumns()}
        rowObjects={[]}
        key={tabName}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
        bodyStyling={tableNumberStyling}
        useTaskPagesApi
        taskPagesApiEndpoint={`${TASKS_ENDPOINT}?${qs}`}
        enablePagination
        tabPaginationOptions={tabPaginationOptions}
      />
    );
  }
};

AssignHearingsTable.propTypes = {
  columns: PropTypes.array,
  tabName: PropTypes.string
};
