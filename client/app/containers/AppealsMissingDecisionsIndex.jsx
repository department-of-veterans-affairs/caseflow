import React, { PropTypes } from 'react';
import Table from '../components/Table';
import { formatDate } from '../util/DateUtil';

const TABLE_HEADERS = ['Veteran', 'Decision Type', 'Decision Date', 'Days in Queue'];

export default class AppealsMissingDecisionsIndex extends React.Component {

  buildAppealRow = (appeal) => [
    `${appeal.veteran_name} (${appeal.vbms_id})`,
    appeal.decision_type,
    formatDate(appeal.decision_date),
    `${appeal.days_in_queue} days`
  ];

  render() {
    let {
      appealsMissingDecisions
    } = this.props;

    return <div className="cf-app-segment cf-app-segment--alt">
      <h1>Claims Missing Decisions - {formatDate(new Date().toDateString())}</h1>

      <div className="usa-grid-full">
        <Table
          headers={TABLE_HEADERS}
          buildRowValues={this.buildAppealRow}
          values={appealsMissingDecisions}
        />
      </div>
    </div>;
  }
}

AppealsMissingDecisionsIndex.propTypes = {
  appealsMissingDecisions: PropTypes.arrayOf(PropTypes.object)
};
