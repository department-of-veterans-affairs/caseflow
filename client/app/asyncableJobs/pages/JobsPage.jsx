import React from 'react';
import { connect } from 'react-redux';

import Button from '../../components/Button';
import Table from '../../components/Table';

class AsyncableJobsPage extends React.PureComponent {
  restartJob = (job, rowNumber) => {
    console.log('restart', job, rowNumber);
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
        valueName: 'submitted_at'
      },
      {
        header: 'Last Attempted',
        valueName: 'attempted_at'
      },
      {
        header: 'Restart',
        align: 'right',
        valueFunction: (job, rowNumber) => {
          return <Button onClick={() => { this.restartJob(job, rowNumber) }} classNames={['usa-button']}>Restart</Button>
        }
      }
    ];

    return <div className="cf-asyncable-jobs-table">
      <h1>{this.props.asyncableJobsKlass}</h1>
      <h3>{this.props.fetchedAt}</h3>
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
