import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import { css } from 'glamor';
import { CSVLink } from 'react-csv';

import Button from 'app/components/Button';
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
import { LIST_SCHEDULE_VIEWS } from 'app/hearings/constants';
import DateRangeFilter from 'app/hearings/components/HearingSchedule/DateRangeFilter';
import { SwitchViewDropdown } from 'app/hearings/components/HearingSchedule/SwitchView';
import { ListTable } from 'app/hearings/components/HearingSchedule/ListTable';

const downloadButtonStyling = css({
  marginTop: '60px'
});

const inlineFormStyling = css({
  '> div': {
    ' & .cf-inline-form': {
      lineHeight: '2em',
      marginTop: '20px'
    },
    '& .question-label': {
      paddingLeft: 0
    },
    '& .cf-form-textinput': {
      marginTop: 0,
      marginRight: 30
    },
    '& input': {
      marginRight: 0
    }
  }
});

const clearfix = css({
  '::after': {
    content: ' ',
    clear: 'both',
    display: 'block'
  }
});

const formatState = (props) => ({
  ...formatTableData(props),
  dateRangeKey: `${props.startDate}->${props.endDate}`,
  prevQueries: JSON.stringify({ sort: {}, filter: {} })
});

const HearingSchedule = (props) => {
  const [state, setState] = useState(formatState(props));

  useEffect(() => {
    if (props.loaded) {
      setState(formatState(props));
    }

    return props.onResetDeleteSuccessful;
  }, [props.loaded]);

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

  const tableKey = !props.user.userHasHearingPrepRole || props.view === LIST_SCHEDULE_VIEWS.DEFAULT_VIEW ?
    `hearings${state.dateRangeKey}` :
    `allHearings${state.dateRangeKey}`;

  const fileName = `HearingSchedule ${props.startDate}-${props.endDate}.csv`;

  console.log('STATE: ', state);

  return (
    <React.Fragment>
      <div {...clearfix}>
        <div className="cf-push-left" {...inlineFormStyling} >
          <DateRangeFilter
            startDateValue={props.startDate}
            startDateChange={props.onViewStartDateChange}
            endDateValue={props.endDate}
            endDateChange={props.onViewEndDateChange}
            onApply={setDateRangeKey}
          />
        </div>
        <div className="cf-push-right list-schedule-buttons" {...downloadButtonStyling} >
          {props.user.userHasHearingPrepRole && <SwitchViewDropdown onSwitchView={props.switchListView} />}
          <CSVLink data={state.rows} headers={state.headers} target="_blank" filename={fileName} >
            <Button classNames={['usa-button-secondary']}>Download current view</Button>
          </CSVLink>
        </div>
      </div>
      <div className="section-hearings-list">
        <ListTable
          fetching={!props.loaded || props.fetching}
          history={history}
          key={tableKey}
          user={props.user}
          hearingScheduleRows={state.rows}
          hearingScheduleColumns={state.columns}
          onQueryUpdate={onQueryUpdate}
        />
      </div>
    </React.Fragment>
  );
};

HearingSchedule.propTypes = {
  endDate: PropTypes.string,
  hearingSchedule: PropTypes.shape({
    scheduledFor: PropTypes.string,
    readableRequestType: PropTypes.string,
    regionalOffice: PropTypes.string,
    room: PropTypes.string,
    judgeId: PropTypes.string,
    judgeName: PropTypes.string,
    updatedOn: PropTypes.string,
    updatedBy: PropTypes.string
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
  hearingSchedule: state.hearingSchedule.hearingSchedule
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
