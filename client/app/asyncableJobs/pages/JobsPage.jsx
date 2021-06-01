/* eslint-disable react/prop-types */
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import moment from 'moment';

import Table from '../../components/Table';
import EasyPagination from '../../components/Pagination/EasyPagination';

import AsyncModelNav from '../components/AsyncModelNav';
import JobRestartButton from '../components/JobRestartButton';

import SearchBar from '../../components/SearchBar';
import ApiUtil from '../../util/ApiUtil';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class AsyncableJobsPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      restarted: 0,
      jobs: this.props.jobs,
      veteranFileNumber: null,
      isFetchingSearchResults: false,
      klassFilterRemoved: false
    };
  }

  formatDate = (datetime) => {
    if (datetime === 'restarted') {
      return datetime;
    }

    // TODO best UX word for this state?
    if (!datetime) {
      return 'queued';
    }

    return moment(datetime).format(DATE_TIME_FORMAT);
  }

  updateVeteranFileNumber = (searchInput) => {
    this.setState({ veteranFileNumber: searchInput });
  }

  handleVeteranIdSearch = () => {
    const searchTerm = this.state.veteranFileNumber;

    this.setState({ isFetchingSearchResults: true });
    window.history.replaceState(null, null, '/jobs');

    ApiUtil.get('/jobs', { headers: { 'veteran-file-number': searchTerm } }).
      then((response) => {
        const jobs = response.body;

        this.setState({
          isFetchingSearchResults: false,
          jobs,
          klassFilterRemoved: true
        });
      }).
      catch(() => {
        this.setState({
          isFetchingSearchResults: false
        });
      });
  }

  render = () => {
    const rowObjects = this.state.jobs;

    const columns = [
      {
        header: 'Name',
        valueFunction: (job, rowId) => {
          const title = `row ${rowId}`;
          const href = `/asyncable_jobs/${job.klass}/jobs/${job.id}`;

          return <a title={title} href={href}>{job.klass} {job.id}</a>;
        }
      },
      {
        header: 'Submitted',
        valueFunction: (job) => {
          return this.formatDate(job.submitted_at);
        }
      },
      {
        header: 'Attempted',
        valueFunction: (job) => {
          return this.formatDate(job.attempted_at);
        }
      },
      {
        header: 'User',
        valueFunction: (job) => {
          if (!job.user) {
            return '';
          }

          return <a href={`/intake/manager?user_css_id=${job.user}`}>{job.user}</a>;
        }
      },
      {
        header: 'Error',
        valueFunction: (job) => {
          let errorStr = job.error;

          if (errorStr) {
            errorStr = errorStr.replace(/\s.+/g, '');
          }

          return <span className="cf-job-error">{errorStr}</span>;
        }
      },
      {
        header: 'Veteran',
        valueFunction: (job) => {
          if (!job.veteran_file_number) {
            return 'unknown';
          }

          return job.veteran_file_number;
        }
      },
      {
        align: 'right',
        valueFunction: (job) => {
          return <JobRestartButton job={job} page={this} />;
        }
      }
    ];

    const rowClassNames = (rowObject) => {
      return rowObject.restarted ? 'cf-success' : '';
    };

    let noResultsMessage;

    if (rowObjects.length === 0) {
      if (this.state.veteranFileNumber) {
        noResultsMessage = <h2>There are no pending jobs for Veteran file '{this.state.veteranFileNumber}'.</h2>;
      } else {
        noResultsMessage = <h2>There are no pending jobs.</h2>;
      }
    }

    return <div className="cf-asyncable-jobs-table">
      <h1>{!this.state.klassFilterRemoved && this.props.asyncableJobKlass} Jobs</h1>
      {noResultsMessage}
      <AsyncModelNav
        models={this.props.models}
        fetchedAt={this.props.fetchedAt}
        asyncableJobKlass={this.props.asyncableJobKlass} />
      <SearchBar
        style={{ marginTop: '0.5em' }}
        size="small"
        title="Search by Veteran file number"
        onChange={this.updateVeteranFileNumber}
        onSubmit={this.handleVeteranIdSearch}
        loading={this.state.isFetchingSearchResults}
        submitUsingEnterKey
      />
      {rowObjects.length > 0 &&
          <div>
            <Table columns={columns} rowObjects={rowObjects} rowClassNames={rowClassNames} slowReRendersAreOk />
            <EasyPagination currentCases={rowObjects.length} pagination={this.props.pagination} />
          </div>
      }
    </div>;
  }
}

AsyncableJobsPage.propTypes = {
  asyncableJobKlass: PropTypes.string,
  fetchedAt: PropTypes.string,
  jobs: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number,
      klass: PropTypes.string
    })
  ),
  models: PropTypes.arrayOf(PropTypes.string),
  pagination: PropTypes.shape({
    current_page: PropTypes.number,
    page_size: PropTypes.number,
    total_jobs: PropTypes.number,
    total_pages: PropTypes.number
  })
};

const JobsPage = connect(
  (state) => ({
    jobs: state.jobs,
    fetchedAt: state.fetchedAt,
    models: state.models,
    pagination: state.pagination,
    asyncableJobKlass: state.asyncableJobKlass
  })
)(AsyncableJobsPage);

export default JobsPage;
