import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';

import IssueList from '../reader/IssueList';

const boldText = css({ fontWeight: 'bold' });

export default class AppealSummary extends React.PureComponent {
  getStyling = () => css({
    '> .appeal-summary-ul': {
      paddingLeft: 0,
      listStyle: 'none'
    },
    '& .issue-level': {
      margin: 0,
    }
  });

  getListElements = () => [{
    label: 'Type',
    valueFunction: () => this.props.appeal.attributes.type
  }, {
    label: 'Power of Attorney',
    valueFunction: () => ''
  }, {
    label: 'Hearing Preference',
    valueFunction: () => ''
  }, {
    label: 'Hearing held',
    valueFunction: () => ''
  }, {
    label: 'Judge at hearing',
    valueFunction: () => ''
  }, {
    label: 'Regional Office',
    valueFunction: () => ''
  }].map(({ label, valueFunction }, idx) => <li key={`appeal-summary-${idx}`}>
    <span {...boldText}>{label}:</span> {valueFunction()}
  </li>);

  render = () => <div {...this.getStyling()}>
    <h2>Appeal Summary</h2>
    <ul className="appeal-summary-ul">
      {this.getListElements()}
    </ul>
    <h2>Issues</h2>
    <IssueList
      appeal={{ issues: this.props.appeal.attributes.issues }}
      className="task-list"
      formatLevelsInNewLine/>
  </div>;
}

AppealSummary.propTypes = {
  appeal: PropTypes.object.isRequired
};
