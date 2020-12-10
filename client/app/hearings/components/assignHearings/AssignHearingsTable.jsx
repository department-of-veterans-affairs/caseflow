import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import {
  AppealDocketTag,
  CaseDetailsInformation,
  SuggestedHearingLocation,
  HearingRequestType
} from './AssignHearingsFields';
import { NoVeteransToAssignMessage } from './Messages';
import VeteranDetail from '../../../queue/VeteranDetail';
import { docketCutoffLineStyle } from './AssignHearingsDocketLine';
import {
  encodeQueryParams,
  getQueryParams
} from '../../../util/QueryParamsUtil';
import { renderAppealType } from '../../../queue/utils';
import { tableNumberStyling } from './styles';
import ApiUtil from '../../../util/ApiUtil';
import LinkToAppeal from './LinkToAppeal';
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

  /* eslint-disable camelcase */
  getFilterOptionsFromApi = (columnName) => {
    const { colsFromApi } = this.state;

    return colsFromApi?.find((col) => col.name === columnName)?.filter_options ?? [];
  }
  /* eslint-enable camelcase */

  /*
   * Gets the list of columns to populate the QueueTable with.
   */
  getColumns = () => {
    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    const { colsFromApi } = this.state;

    if (_.isNil(selectedHearingDay) || _.isNil(colsFromApi)) {
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
        header: 'Appeal Stream Type',
        align: 'left',
        valueFunction: (row) => renderAppealType({
          caseType: row.appeal.caseType,
          isAdvancedOnDocket: row.appeal.isAdvancedOnDocket
        })
      },
      {
        name: 'hearingRequestType',
        header: 'Hearing Type',
        align: 'left',
        columnName: 'Hearing Type',
        valueFunction: (row) => (
          <HearingRequestType
            hearingRequestType={row.hearingRequestType}
            isFormerTravel={row.isFormerTravel}
          />
        ),
        label: 'Filter by hearing request type',
        enableFilter: true,
        anyFiltersAreSet: true,
        filterOptions: this.getFilterOptionsFromApi(QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME)
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
        filterOptions: this.getFilterOptionsFromApi(QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME)
      },
      {
        name: 'veteranState',
        header: 'Veteran State of Residence',
        align: 'left',
        valueFunction: (row) => (
          <VeteranDetail
            appealId={row.externalAppealId}
            stateOnly
          />
        )
      },
      {
        name: 'powerOfAttorneyName',
        header: 'Power of Attorney (POA)',
        valueName: 'powerOfAttorneyName',
        columnName: 'Power of Attorney',
        align: 'left',
        label: 'Filter by Power of Attorney',
        enableFilter: true,
        anyFiltersAreSet: true,
        filterOptions: this.getFilterOptionsFromApi(QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME)
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

    const {
      total_task_count: totalTaskCount,
      tasks_per_page: tasksPerPage,
      docket_line_index: amaDocketLineIndex
    } = response;

    this.setState({
      showNoVeteransToAssignError: totalTaskCount === 0 && !filtered,
      // null index means do not display the line at all
      // -1 index means display line at the very start of the list
      amaDocketLineIndex,
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
  selectedHearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string
  }),

  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,

  tabName: PropTypes.string
};
