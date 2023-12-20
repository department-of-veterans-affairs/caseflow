import React from 'react';
import moment from 'moment';
import PropTypes from 'prop-types';
import DropdownButton from '../../components/DropdownButton';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

export default class AsyncModelNav extends React.PureComponent {
  modelNameLinks = () => {
    const links = [];
    const modelNames = this.props.models.sort();
    const numLinks = modelNames.length;

    for (let modelName of modelNames) {
      const url = `/asyncable_jobs/${modelName}/jobs`;
      let modelLink;

      if (numLinks > 4) {
        modelLink = {
          title: modelName,
          target: url
        };
      } else {
        modelLink = <span key={modelName} className="cf-model-jobs-link"><a href={url}>{modelName}</a></span>;
      }

      links.push(modelLink);
    }

    return numLinks > 4 ? <DropdownButton lists={links} label="Filter by Job Type" /> : links;
  }

  render = () => {
    const currentPath = this.props.asyncableJobKlass ?
      `/asyncable_jobs/${this.props.asyncableJobKlass}/jobs` :
      '/jobs';

    return <div>
      <strong>Last updated:</strong> {moment(this.props.fetchedAt).format(DATE_TIME_FORMAT)}
      <div style={{ marginTop: '.5em' }}>
        <a style={{ marginRight: '.5em' }} href="/jobs" className="cf-link-btn">All jobs</a>
        {this.modelNameLinks()}
        <a style={{ float: 'right' }} href={`${currentPath}.csv`} className="cf-link-btn">Download as CSV</a>
      </div>
    </div>;
  }
}

AsyncModelNav.propTypes = {
  models: PropTypes.array,
  fetchedAt: PropTypes.string,
  asyncableJobKlass: PropTypes.string
};
