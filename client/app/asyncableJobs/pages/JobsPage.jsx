import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';

import Button from '../../components/Button';
import Table from '../../components/Table';

import ApiUtil from '../../util/ApiUtil';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class AsyncableJobsPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      jobsRestarted: {},
      jobsRestarting: {}
    };
  }

  restartJob = (job) => {
    let jobsRestarting = { ...this.state.jobsRestarting };

    jobsRestarting[job.id] = true;
    this.setState({ jobsRestarting });
    this.sendRestart(job);
  }

  sendRestart = (job) => {
    let page = this;

    ApiUtil.patch(`/asyncable_jobs/${job.klass}/jobs/${job.id}`, {}).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          Object.assign(job, responseObject);

          // TODO null it on server? responseObject.error;
          job.error = '';

          job.restarted = true;

          let jobsRestarted = { ...page.state.jobsRestarted };
          let jobsRestarting = { ...page.state.jobsRestarting };

          jobsRestarted[job.id] = true;
          jobsRestarting[job.id] = false;
          page.setState({
            jobsRestarted,
            jobsRestarting
          });
        },
        (error) => {
          throw error;
        }
      ).
      catch((error) => error);
  }

  getButtonClassNames = (job) => {
    let classNames = ['usa-button'];

    if (this.state.jobsRestarting[job.id] || this.state.jobsRestarted[job.id]) {
      classNames.push('usa-button-disabled');
    }

    return classNames;
  }

  getButtonText = (job) => {
    let txt = 'Restart';

    if (this.state.jobsRestarting[job.id]) {
      txt = 'Restarting';
    } else if (this.state.jobsRestarted[job.id]) {
      txt = 'Restarted';
    }

    return txt;
  }

  render = () => {
    const rowObjects = this.props.jobs;

    if (rowObjects.length === 0) {
      return 'Success! There are no pending jobs.';
    }

    const columns = [
      {
        header: 'Name',
        valueFunction: (job) => {
          return <a href={`/asyncable_jobs/${job.klass}/jobs`}>{job.klass}</a>;
        }
      },
      {
        header: 'Submitted',
        valueFunction: (job) => {
          if (job.submitted_at === 'restarted') {
            return job.submitted_at;
          }

          return moment(job.submitted_at).format(DATE_TIME_FORMAT);
        }
      },
      {
        header: 'Last Attempted',
        valueFunction: (job) => {
          if (!job.attempted_at) {
            return 'never';
          }

          return moment(job.attempted_at).format(DATE_TIME_FORMAT);
        }
      },
      {
        header: 'Error',
        valueFunction: (job) => {
          return <span className="cf-job-error">{job.error}</span>;
        }
      },
      {
        header: 'Veteran',
        valueName: 'veteran_file_number'
      },
      {
        header: 'Restart',
        align: 'right',
        valueFunction: (job) => {
          return <Button
            id={`job-${job.klass}-${job.id}`}
            loading={this.state.jobsRestarting[job.id]}
            loadingText="Restarting..."
            onClick={() => {
              this.restartJob(job);
            }}
            classNames={this.getButtonClassNames(job)}
          >{this.getButtonText(job)}</Button>;
        }
      }
    ];

    const rowClassNames = (rowObject) => {
      return rowObject.restarted ? 'cf-success' : '';
    };

    return <div className="cf-asyncable-jobs-table">
      <h1>{this.props.asyncableJobKlass} Jobs</h1>
      <div>
        <strong>Last updated:</strong> {moment(this.props.fetchedAt).format(DATE_TIME_FORMAT)}
        &nbsp;&#183;&nbsp;
        <a href="/jobs">All jobs</a>
      </div>
      <Table columns={columns} rowObjects={rowObjects} rowClassNames={rowClassNames} slowReRendersAreOk />
    </div>;
  }
}

const JobsPage = connect(
  (state) => ({
    jobs: state.jobs,
    fetchedAt: state.fetchedAt,
    asyncableJobKlass: state.asyncableJobKlass
  })
)(AsyncableJobsPage);

export default JobsPage;
