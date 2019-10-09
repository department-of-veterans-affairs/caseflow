/* eslint-disable react/prop-types */
import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';

import AsyncModelNav from '../components/AsyncModelNav';
import JobRestartButton from '../components/JobRestartButton';
import JobNotes from '../components/JobNotes';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class AsyncableJobPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      restarted: 0
    };
  }

  formatDate = (datetime) => {
    if (!datetime) {
      return 'n/a';
    }

    return moment(datetime).format(DATE_TIME_FORMAT);
  }

  render = () => {
    const { job, notes } = this.props;

    return <div className="cf-asyncable-job-table">
      <h1>{this.props.asyncableJobKlass} Job {job.id}</h1>
      <AsyncModelNav models={[]} fetchedAt={this.props.fetchedAt} />
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
            <th>Canceled</th>
            <td>{this.formatDate(job.canceled_at)}</td>
          </tr>
          <tr>
            <th>Processed</th>
            <td>{this.formatDate(job.processed_at)}</td>
          </tr>
          <tr>
            <th>Error</th>
            <td>{job.error}</td>
          </tr>
          <tr>
            <th>User</th>
            <td><a href={`/intake/manager?user_css_id=${job.user}`}>{job.user}</a></td>
          </tr>
        </tbody>
      </table>
      <div>
        <JobRestartButton job={job} page={this} />
      </div>
      <div>
        <JobNotes job={job} notes={notes} />
      </div>
    </div>;
  }
}

const JobPage = connect(
  (state) => ({
    job: state.job,
    notes: state.notes,
    fetchedAt: state.fetchedAt,
    models: state.models,
    asyncableJobKlass: state.asyncableJobKlass
  })
)(AsyncableJobPage);

export default JobPage;
