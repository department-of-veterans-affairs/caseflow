import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

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

  getAppealAttr = (attr) => _.get(this.props.appeal.attributes, attr)

  getLatestHearing = () => {
    const hearings = this.getAppealAttr('hearings');

    if (!hearings.length) {
      return {};
    }
    return _.orderBy(hearings, 'held_on', 'desc')[0];
  }

  getListElements = () => [{
    label: 'Type',
    valueFunction: () => this.getAppealAttr('type')
  }, {
    label: 'Power of Attorney',
    valueFunction: () => this.getAppealAttr('power_of_attorney')
  }, {
    label: 'Hearing Preference',
    valueFunction: () => ''
  }, {
    label: 'Hearing held',
    valueFunction: () => this.getLatestHearing().held_on ? moment(this.getLatestHearing().held_on).format('MM/DD/YY') : ''
  }, {
    label: 'Judge at hearing',
    valueFunction: () => this.getLatestHearing().held_by
  }, {
    label: 'Regional Office',
    valueFunction: () => `${this.getAppealAttr('regional_office.city')} (${this.getAppealAttr('regional_office.key').replace('RO', '')})`
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
