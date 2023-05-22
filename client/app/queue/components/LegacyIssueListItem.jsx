import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import {
  getIssueProgramDescription,
  getIssueTypeDescription,
  getIssueDiagnosticCodeLabel
} from '../utils';
import { boldText } from '../constants';
import ISSUE_INFO from '../../../constants/ISSUE_INFO';
import VACOLS_DISPOSITIONS_BY_ID from '../../../constants/VACOLS_DISPOSITIONS_BY_ID';

const minimalLeftPadding = css({ paddingLeft: '0.5rem' });
const noteMarginTop = css({ marginTop: '1.5rem' });
const issueMarginTop = css({ marginTop: '0.5rem' });
const issueLevelStyling = css({
  display: 'inline-block',
  width: '100%',
  marginLeft: '4.5rem'
});
const leftAlignTd = css({
  paddingLeft: 0,
  paddingRight: 0
});

const specialIssuesFormatting = (props) => {
  const mstStatus = props.legacy_appeal_vacols_mst;
  const pactStatus = props.legacy_appeal_vacols_pact;

  if (!mstStatus && !pactStatus) {
    return 'None';
  } else if (mstStatus && pactStatus) {
    return 'MST and PACT';
  } else if (mstStatus) {
    return 'MST';
  } else if (pactStatus) {
    return 'PACT';
  }
};

export const dispositionLabelForDescription = (disposition) => {
  // Use the disposition description from constants in order to get the proper capitalization.
  return disposition ? `${disposition} - ${VACOLS_DISPOSITIONS_BY_ID[disposition]}` : null;
};

export default class LegacyIssueListItem extends React.PureComponent {
  formatIdx = () => <td {...leftAlignTd} width="10px">
    {this.props.idx}.
  </td>;

  // eslint-disable-next-line max-statements
  getIssueLevelValues = () => {
    const {
      issue: {
        program,
        type,
        levels,
        codes,
        codes: [
          isslev1,
          isslev2
        ]
      }
    } = this.props;

    const issueLevels = [];
    const vacolsIssue = ISSUE_INFO[program].levels[type];

    if (!vacolsIssue) {
      return levels;
    }

    const issueLevel1 = _.get(vacolsIssue.levels, isslev1);
    const issueLevel2 = _.get(issueLevel1, ['levels', isslev2]);
    const diagnosticCodeLabel = getIssueDiagnosticCodeLabel(_.last(codes));

    if (issueLevel1) {
      issueLevels.push(issueLevel1.description);

      if (issueLevel2) {
        issueLevels.push(issueLevel2.description);
      }
    }
    issueLevels.push(diagnosticCodeLabel);

    return issueLevels;
  };

  formatLevels = () => this.getIssueLevelValues().map((code, idx) =>
    <div key={idx} {...issueMarginTop}>
      <span key={code} {...issueLevelStyling}>
        {_.get(code, 'description', code)}
      </span>
    </div>
  );

  render = () => {
    const {
      issue,
      issue: {
        disposition,
        levels,
        note
      },
      issuesOnly,
      showDisposition
    } = this.props;
    let issueContent = <span />;

    if (issuesOnly) {
      issueContent = <React.Fragment>
        {getIssueTypeDescription(issue)} {levels.join(', ')}
      </React.Fragment>;
    } else {
      issueContent = <React.Fragment>
        <span {...boldText}>Program:</span> {getIssueProgramDescription(issue)}
        <div {...issueMarginTop}>
          <span {...boldText}>Issue:</span> {getIssueTypeDescription(issue)} {this.formatLevels()}
        </div>
        <div {...noteMarginTop}>
          <span {...boldText}>Note:</span> {note}
        </div>
        <div {...noteMarginTop}>
          <span {...boldText}>Special Issues: </span> {specialIssuesFormatting(issue)}
        </div>
      </React.Fragment>;
    }

    return <React.Fragment>
      {this.formatIdx()}
      <td {...minimalLeftPadding}>
        {issueContent}
      </td>
      {!issuesOnly && disposition && showDisposition && <td>
        <span {...boldText}>Disposition:</span> {dispositionLabelForDescription(disposition)}
      </td>}
    </React.Fragment>;
  };
}

LegacyIssueListItem.propTypes = {
  issue: PropTypes.object.isRequired,
  issuesOnly: PropTypes.bool,
  idx: PropTypes.number.isRequired,
  showDisposition: PropTypes.bool
};

LegacyIssueListItem.defaultProps = {
  issuesOnly: false,
  showDisposition: true
};
