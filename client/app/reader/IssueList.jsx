import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import { NO_ISSUES_ON_APPEAL_MSG } from './constants';

const issueListStyle = css({
  display: 'inline'
});
const issueLevelStyle = css({
  marginBottom: 0,
  marginTop: 0
});

export default class IssueList extends React.PureComponent {

  csvIssueLevels = (issue) => issue.levels ? issue.levels.join(', ') : '';

  /**
   * Returns levels in a new line if formatLevelsInNewLine is true otherwise
   * the levels are returned as a comma separated string in one line.
   */
  issueLevels = (issue, formatLevelsInNewLine = this.props.formatLevelsInNewLine) => {
    if (formatLevelsInNewLine) {
      return issue.levels.map((level) =>
        <p {...issueLevelStyle} key={level}>
          {level}
        </p>);
    }

    return this.csvIssueLevels(issue);
  };

  render = () => {
    const {
      appeal,
      className
    } = this.props;
    let listContent = NO_ISSUES_ON_APPEAL_MSG;

    if (!_.isEmpty(appeal.issues)) {
      listContent = <ol className={className}>
        {appeal.issues.map((issue) =>
          <li key={`${issue.id}_${issue.vacols_sequence_id}`}>
            <span>
              {issue.type} {this.issueLevels(issue)}
            </span>
          </li>
        )}
      </ol>;
    }

    return <div {...issueListStyle}>
      {listContent}
    </div>;
  };
}

IssueList.propTypes = {
  appeal: PropTypes.object.isRequired,
  className: PropTypes.string,
  formatLevelsInNewLine: PropTypes.bool
};

IssueList.defaultProps = {
  className: '',
  formatLevelsInNewLine: false
};
