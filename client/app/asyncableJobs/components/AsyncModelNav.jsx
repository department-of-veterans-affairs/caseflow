import React from 'react';
import moment from 'moment';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

export default class AsyncModelNav extends React.PureComponent {
  modelNameLinks = () => {
    let links = [];

    for (let modelName of this.props.models.sort()) {
      let modelLink = <span key={modelName} className="cf-model-jobs-link">
        <a href={`/asyncable_jobs/${modelName}/jobs`}>{modelName}</a>
      </span>;

      links.push(modelLink);
    }

    return links;
  }

  render = () => {

    return <div>
      <strong>Last updated:</strong> {moment(this.props.fetchedAt).format(DATE_TIME_FORMAT)}
      &nbsp;&#183;&nbsp;
      <a href="/jobs">All jobs</a>
      <div>{this.modelNameLinks()}</div>
    </div>;
  }
}
