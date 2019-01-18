import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';

import Button from '../../components/Button';
import Table from '../../components/Table';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class AsyncableJobsPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      jobsRestarted: {}
    };
  }

  restartJob = (job, rowNumber) => {
    console.log('restart', job, rowNumber, this);
    let jobsRestarted = { ...this.state.jobsRestarted };
    jobsRestarted[job.id] = true;
    this.setState({ jobsRestarted });
    job.submitted_at = 'restarted'; // TODO in ajax onSuccess
  }

  getButtonClassNames = (job, rowNumber) => {
    let classNames = ['usa-button'];

    if (this.state.jobsRestarted[job.id]) {
      classNames.push('usa-button-disabled');
    }

    return classNames;
  }

  render = () => {
    console.log(this.props);

    const rowObjects = this.props.jobs;

    const columns = [
      {
        header: 'Name',
        valueName: 'klass'
      },
      {
        header: 'Submitted',
        valueFunction: (job, rowNumber) => {
          if (job.submitted_at === 'restarted') {
            return job.submitted_at;
          }

          return moment(job.submitted_at).format(DATE_TIME_FORMAT);
        }
      },
      {
        header: 'Last Attempted',
        valueFunction: (job, rowNumber) => {
          if (!job.attempted_at) {
            return 'never';
          }

          return moment(job.attempted_at).format(DATE_TIME_FORMAT);
        }
      },
      {
        header: 'Error',
        valueName: 'error'
      },
      {
        header: 'Restart',
        align: 'right',
        valueFunction: (job, rowNumber) => {
          return <Button
            id={`job-${job.id}`}
            loading={this.state.jobsRestarted[job.id]}
            loadingText="Restarting..."
            onClick={() => {
              this.restartJob(job, rowNumber);
            }}
            classNames={this.getButtonClassNames(job, rowNumber)}
          >Restart</Button>;
        }
      }
    ];

    return <div className="cf-asyncable-jobs-table">
      <h1>{this.props.asyncableJobsKlass}</h1>
      <div><strong>Last updated:</strong> {moment(this.props.fetchedAt).format(DATE_TIME_FORMAT)}</div>
      <Table columns={columns} rowObjects={rowObjects} slowReRendersAreOk />
    </div>;
  }
}

const JobsPage = connect(
  (state) => ({
    jobs: state.jobs,
    fetchedAt: state.fetchedAt,
    asyncableJobsKlass: state.asyncableJobsKlass
  })
)(AsyncableJobsPage);

export default JobsPage;
