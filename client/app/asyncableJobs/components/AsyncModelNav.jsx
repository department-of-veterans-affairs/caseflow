import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

export default class AsyncModelNav extends React.PureComponent {
  modelNameLinks = () => {
    const models = this.props.models.sort().map((model) => {
      return {
        title: model,
        value: model,
        button: true
      };
    });

    return <DropdownButton
      lists={models}
      label="Filter by Job Type"
      onClick={this.props.filterOnChange}
    />;
  }

  render = () => {
    return <div>
      <strong>Last updated:</strong> {moment(this.props.fetchedAt).format(DATE_TIME_FORMAT)}
      <div style={{ marginTop: '.5em' }}>
        <a style={{ marginRight: '.5em' }}
          onClick={() => this.props.filterOnChange(null)}
          className="cf-link-btn"
        >
          All jobs
        </a>
        {this.modelNameLinks()}
        <a style={{ float: 'right' }} href={'/jobs.csv'} className="cf-link-btn">Download as CSV</a>
      </div>
    </div>;
  }
}

AsyncModelNav.propTypes = {
  models: PropTypes.array,
  fetchedAt: PropTypes.string,
  asyncableJobKlass: PropTypes.string,
  filterOnChange: PropTypes.func.isRequired,
};
