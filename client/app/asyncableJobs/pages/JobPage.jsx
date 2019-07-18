import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';

import AsyncModelNav from '../components/AsyncModelNav';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class AsyncableJobPage extends React.PureComponent {
  formatDate = (datetime) => {
    if (!datetime) {
      return 'queued';
    }

    return moment(datetime).format(DATE_TIME_FORMAT);
  }

  render = () => {
    const { job } = this.props;

    return <div className="cf-asyncable-jobs-table">
      <h1>{this.props.asyncableJobKlass} Job {job.id}</h1>
      <AsyncModelNav models={this.props.models} fetchedAt={this.props.fetchedAt} />
      <hr />
      <table className="cf-job-details">
        <tbody>
          <tr>
            <th>ID</th>
            <td>{job.id}</td>
          </tr>
          <tr>
            <th>Veteran</th>
            <td>{job.veteran_file_number}</td>
          </tr>
          <tr>
            <th>Originally Submitted</th>
            <td>{this.formatDate(job.submitted_at)}</td>
          </tr>
          <tr>
            <th>Last Submitted</th>
            <td>{this.formatDate(job.last_submitted_at)}</td>
          </tr>
          <tr>
            <th>Last Attempted</th>
            <td>{this.formatDate(job.attempted_at)}</td>
          </tr>
          <tr>
            <th>Error</th>
            <td>{job.error}</td>
          </tr>
        </tbody>
      </table>
    </div>;
  }
}

const JobPage = connect(
  (state) => ({
    job: state.job,
    fetchedAt: state.fetchedAt,
    models: state.models,
    asyncableJobKlass: state.asyncableJobKlass
  })
)(AsyncableJobPage);

export default JobPage;
