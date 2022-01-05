import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { formatTableData } from 'app/hearings/utils';
import {
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onReceiveHearingSchedule,
  onViewStartDateChange,
  onViewEndDateChange,
  onResetDeleteSuccessful
} from 'app/hearings/actions/hearingScheduleActions';
import { HearingScheduleHeader } from 'app/hearings/components/HearingSchedule/Header';
import QueueTable from 'app/queue/QueueTable';
import Pagination from 'app/components/Pagination/Pagination';

const formatState = (props) => ({
  ...formatTableData(props),
  dateRangeKey: `${props.startDate}->${props.endDate}`,
  prevQueries: JSON.stringify({ sort: {}, filter: {} })
});

const HearingSchedule = (props) => {
  const [state, setState] = useState(formatState(props));

  useEffect(() => {
    return props.onResetDeleteSuccessful;
  }, []);

  const setDateRangeKey = () => {
    setState({ ...state, dateRangeKey: `${props.startDate}->${props.endDate}` });

    // show first page by default by sending index of 0
    props.fetchHearings(0);
  };

  const onQueryUpdate = (params) => {
    if (JSON.stringify(params) === state.prevQueries) {
      return;
    }

    setState({ ...state, prevQueries: JSON.stringify(params) });

    let queries = { sort: null, filter: null };

    if (params.sort?.sortCol) {
      const sortDirection = params.sort.ascending ? 'asc' : 'desc';

      queries.sort = { column: params.sort.sortCol?.sortParamName, direction: sortDirection };
    }

    const filterKeys = Object.keys(params.filter);

    if (filterKeys.length > 0) {
      // Find column in order to translate filter[key] into queryValue,
      // which are properties in column.filterOptions
      // ex: translate filter[key] "Anchorage, AK" into queryValue "RO63"
      let filters = {};

      filterKeys.forEach((key) => {
        const column = state.columns.find((col) => col.columnName === key);
        const labels = params.filter[key];
        const values = [];

        column.filterOptions?.map((option) => {
          if (labels.includes(option.value)) {
            values.push(option.queryValue);
          }
        });
        if (values.length > 0) {
          filters[column.filterParamName] = values;
        }
      });
      queries.filter = filters;
    }

    // Note: coordinate handling of "blank" selections for Judge and Regional Office with back-end
    props.updateQueries(queries);
  };

  const fileName = `HearingSchedule ${props.startDate}-${props.endDate}.csv`;

  return (
    <AppSegment filledBackground>
      <HearingScheduleHeader {...props} fileName={fileName} setDateRangeKey={setDateRangeKey} />
      <div className="section-hearings-list">
        <QueueTable
          fetching={!props.loaded || props.fetching}
          columns={props.hearingSchedule?.columns || []}
          rowObjects={props.hearingSchedule?.rows || []}
          returnQueries={onQueryUpdate}
          summary="hearing-schedule"
          slowReRendersAreOk
          useHearingsApi
        />
        <Pagination {...props.pagination} updatePage={props.updatePage} />
      </div>
    </AppSegment>
  );
};

HearingSchedule.propTypes = {
  loaded: PropTypes.bool,
  fetching: PropTypes.bool,
  endDate: PropTypes.string,
  hearingSchedule: PropTypes.shape({
    rows: PropTypes.array,
    columns: PropTypes.array,
  }),
  fetchHearings: PropTypes.func.isRequired,
  updateQueries: PropTypes.func.isRequired,
  onResetDeleteSuccessful: PropTypes.func,
  onViewStartDateChange: PropTypes.func,
  onViewEndDateChange: PropTypes.func,
  history: PropTypes.object,
  startDate: PropTypes.string,
  switchListView: PropTypes.func,
  user: PropTypes.object,
  view: PropTypes.string,
  filterOptions: PropTypes.object
};

const mapStateToProps = (state) => ({
  filterTypeIsOpen: state.hearingSchedule.filterTypeIsOpen,
  filterLocationIsOpen: state.hearingSchedule.filterLocationIsOpen,
  filterVljIsOpen: state.hearingSchedule.filterVljIsOpen,
  startDate: state.hearingSchedule.viewStartDate,
  endDate: state.hearingSchedule.viewEndDate,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onResetDeleteSuccessful,
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(HearingSchedule));
