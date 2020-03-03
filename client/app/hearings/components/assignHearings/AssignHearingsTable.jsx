import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import {
  AppealDocketTag,
  CaseDetailsInformation,
  SuggestedHearingLocation
} from './AssignHearingsFields';
import { NoVeteransToAssignMessage } from './Messages';
import {
  encodeQueryParams,
  getQueryParams
} from '../../../util/QueryParamsUtil';
import {
  docketCutoffLineStyle,
  getIndexOfDocketLine
} from './AssignHearingsDocketLine';
import { renderAppealType } from '../../../queue/utils';
import { tableNumberStyling } from './styles';
import ApiUtil from '../../../util/ApiUtil';
import LinkToAppeal from './LinkToAppeal';
import PowerOfAttorneyDetail from '../../../queue/PowerOfAttorneyDetail';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG';
import QueueTable from '../../../queue/QueueTable';

const TASKS_ENDPOINT = '/hearings/schedule_hearing_tasks';
const COLUMNS_ENDPOINT = '/hearings/schedule_hearing_tasks_columns';

export default class AssignHearingsTable extends React.PureComponent {

  constructor(props) {
    super(props);

    this.state = {
      showNoVeteransToAssignError: false,
      colsFromApi: null,
      amaDocketLineIndex: null,
      rowOffset: 0
    };
  }

  componentDidMount() {
    this.getColumnsFromApi();
  }

  getColumnsFromApi = () => {
    const { tabName, selectedRegionalOffice } = this.props;
    const qs = encodeQueryParams({
      [QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM]: tabName,
      regional_office_key: selectedRegionalOffice
    });

    return ApiUtil.get(`${COLUMNS_ENDPOINT}${qs}`).
      then((response) => {
        this.setState({ colsFromApi: response.body.columns });
      });
  }

  endOfNextMonth = () => (
    moment().add(1, 'months').
      endOf('month')
  )

  amaDocketCutoffLineIndex = (appeals) => {
    const { tabName } = this.props;

    // Docket line only applies to AMA docket.
    if (tabName !== QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME) {
      return null;
    }

    return getIndexOfDocketLine(appeals, this.endOfNextMonth());
  }

  formatSuggestedHearingLocation = (suggestedLocation) => {
    if (_.isNull(suggestedLocation) || _.isUndefined(suggestedLocation)) {
      return null;
    }

    const { city, state } = suggestedLocation;
    const formattedFacilityType = suggestedLocation.formatted_facility_type;

    return `${city}, ${state} ${formattedFacilityType}`;
  }

  getCurrentPageNumberFromUrl = () => {
    const queryParams = getQueryParams(window.location.search);

    return Number(queryParams[QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]) || 1;
  }

  /*
   * Gets the list of columns to populate the QueueTable with.
   */
  getColumns = () => {
    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    const { colsFromApi } = this.state;

    if (_.isNil(selectedHearingDay)) {
      return [];
    }

    const columns = [
      {
        header: '',
        align: 'left',
        // Since this column isn't tied to anything in the input row, _value will
        // always be undefined.
        valueFunction: (_value, rowId) => <span>{rowId + this.state.rowOffset}.</span>
      },
      {
        name: 'caseDetails',
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
        name: 'type',
        header: 'Type(s)',
        align: 'left',
        valueFunction: (row) => renderAppealType({
          caseType: row.appeal.caseType,
          isAdvancedOnDocket: row.appeal.isAdvancedOnDocket
        })
      },
      {
        name: 'docketNum',
        header: 'Docket Number',
        align: 'left',
        valueFunction: (row) => (
          <AppealDocketTag appeal={row.appeal} />
        )
      },
      {
        name: 'suggestedLocation',
        header: 'Suggested Location',
        align: 'left',
        columnName: 'Suggested Location',
        valueFunction: (row) => (
          <SuggestedHearingLocation
            suggestedLocation={row.suggestedHearingLocation}
            format={this.formatSuggestedHearingLocation}
          />
        ),
        label: 'Filter by location',
        filterValueTransform: this.formatSuggestedHearingLocation,
        enableFilter: true,
        anyFiltersAreSet: true,
        filterOptions: colsFromApi && colsFromApi.find((col) => col.name === 'suggestedLocation').filter_options
      },
      {
        name: 'powerOfAttorneyName',
        header: 'Power of Attorney (POA)',
        columnName: 'Power of Attorney',
        align: 'left',
        valueFunction: (row) => (
          <PowerOfAttorneyDetail
            key={`poa-${row.externalAppealId}-detail`}
            appealId={row.externalAppealId}
            displayNameOnly
          />
        ),
        label: 'Filter by Power of Attorney',
        enableFilter: true,
        anyFiltersAreSet: true,
        filterValueTransform: (_value, row) => {
          const { powerOfAttorneyNamesForAppeals } = this.props;

          return powerOfAttorneyNamesForAppeals[row.externalAppealId];
        },
        filterOptions: colsFromApi && colsFromApi.find((col) => col.name === 'powerOfAttorneyName').filter_options
      }
    ];

    return columns;
  }

  // Callback when the QueueTable receives tasks from the API. If there are no
  // tasks for the table to display at all (not just for the current page),
  // update this component to show an error.
  // Filtered indicates if any filters are active in which case
  // we do not wanna show the error if no tasks are returned.
  onPageLoaded = (response, currentPage, filtered = false) => {
    if (!response) {
      return;
    }

    const { tasks, total_task_count: totalTaskCount, tasks_per_page: tasksPerPage } = response;
    const amaDocketLineIndex = this.amaDocketCutoffLineIndex(
      tasks.map((task) => task.appeal).filter((appeal) => !appeal.isLegacy)
    );

    this.setState({
      showNoVeteransToAssignError: totalTaskCount === 0 && !filtered,
      // null index means do not display the line at all
      // -1 index means display line at the very start of the list
      amaDocketLineIndex: currentPage > 0 && amaDocketLineIndex === -1 ? null : amaDocketLineIndex,
      rowOffset: (tasksPerPage * currentPage) + 1
    });
  }

  render = () => {
    const { tabName, selectedRegionalOffice } = this.props;
    const qs = encodeQueryParams({
      [QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM]: tabName,
      regional_office_key: selectedRegionalOffice
    });
    const tabPaginationOptions = {
      onPageLoaded: this.onPageLoaded
    };

    // Clicked prop indicates if the tab was clicked by user.
    // If not clicked, then the page was reloaded in which
    // case we want to read page number from query string.
    // Otherwise, we do not pass anything since QueueTable sets
    // default page to be 1.
    if (!this.props.clicked) {
      tabPaginationOptions[[QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM]] = this.getCurrentPageNumberFromUrl();
    }

    if (this.state.showNoVeteransToAssignError) {
      return <NoVeteransToAssignMessage />;
    }

    let docketStyle = {};

    if (this.state.amaDocketLineIndex !== null) {
      docketStyle = docketCutoffLineStyle(
        this.state.amaDocketLineIndex,
        this.endOfNextMonth().format('MMMM YYYY')
      );
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
        taskPagesApiEndpoint={`${TASKS_ENDPOINT}${qs}`}
        enablePagination
        tabPaginationOptions={tabPaginationOptions}
        styling={docketStyle}
      />
    );
  }
}

AssignHearingsTable.propTypes = {
  columns: PropTypes.array,
  clicked: PropTypes.bool,
  // Appeal ID => Attorney Name Array
  powerOfAttorneyNamesForAppeals: PropTypes.objectOf(PropTypes.string),
  selectedHearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string
  }),
  selectedRegionalOffice: PropTypes.string,
  tabName: PropTypes.string
};
