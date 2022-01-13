import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

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

const HearingSchedule = (props) => {
  useEffect(() => {
    return props.onResetDeleteSuccessful;
  }, []);

  const fileName = `HearingSchedule ${props.startDate}-${props.endDate}.csv`;

  return (
    <AppSegment filledBackground>
      <HearingScheduleHeader {...props} headers={props.hearingSchedule?.headers} fileName={fileName} />
      <div className="section-hearings-list">
        <Pagination {...props.pagination} updatePage={props.updatePage} />
        <QueueTable
          defaultSort={{
            sortColName: 'Date',
            sortAscending: true
          }}
          fetching={!props.loaded || props.fetching}
          columns={props.hearingSchedule?.columns || []}
          rowObjects={props.hearingSchedule?.rows || []}
          summary="hearing-schedule"
          slowReRendersAreOk
          useHearingsApi
          fetchPaginatedData={props.fetchHearings}
          className="hearings-schedule-table"
        />
        <Pagination {...props.pagination} updatePage={props.updatePage} />
      </div>
    </AppSegment>
  );
};

HearingSchedule.propTypes = {
  pagination: PropTypes.object,
  updatePage: PropTypes.func,
  loaded: PropTypes.bool,
  fetching: PropTypes.bool,
  endDate: PropTypes.string,
  hearingSchedule: PropTypes.shape({
    rows: PropTypes.array,
    columns: PropTypes.array,
  }),
  fetchHearings: PropTypes.func.isRequired,
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
