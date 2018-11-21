// @flow
import * as React from 'react';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import Button from '../../components/Button';

import IssueListItem from './IssueListItem';
import LegacyIssueListItem from './LegacyIssueListItem';
import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';

const contestedIssueStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  padding: '0 20px',
  margin: '10px 0'
});

const indentedIssueStyling = css({
  margin: '0 10px'
});

const buttonDiv = css({
  textAlign: 'right',
  marginBottom: '20px'
});

export default class ContestedIssues extends React.PureComponent<Props> {
  render = () => {
    const {
      requestIssues,
      addDecisionHandler
    } = this.props;

    return requestIssues.map((issue) => {
      return <React.Fragment key={issue.description}>
        <div {...contestedIssueStyling}>
          Contested Issue
        </div>
        <div {...indentedIssueStyling}>
          {issue.description}
          <div>Note: "{issue.notes}"</div>
        </div>
        { addDecisionHandler &&
          <div {...buttonDiv}>
            <Button
              name="+ Add Decision"
              onClick={addDecisionHandler([issue.id])}
              classNames={['usa-button-secondary']}
            />
          </div>
        }
      </React.Fragment>;
    });
  }
}
