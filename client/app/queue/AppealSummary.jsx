import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import QueueIssueList from './QueueIssueList';
import { boldText } from './constants';

export default class AppealSummary extends React.PureComponent {
  getStyling = () => css({
    '> .appeal-summary-ul': {
      paddingLeft: 0,
      listStyle: 'none'
    },
    '& .task-list': {
      paddingLeft: '1.5rem'
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
    valueFunction: () => this.getLatestHearing().held_on ? moment(this.getLatestHearing().held_on).format('M/D/YY') : ''
  }, {
    label: 'Judge at hearing',
    valueFunction: () => this.getLatestHearing().held_by
  }, {
    label: 'Regional Office',
    valueFunction: () => {
      const {
        city,
        key
      } = this.getAppealAttr('regional_office');

      return `${city} (${key.replace('RO', '')})`;
    }
  }].map(({ label, valueFunction }, idx) => <li key={`appeal-summary-${idx}`}>
    <span {...boldText}>{label}:</span> {valueFunction()}
  </li>);

  render = () => <div {...this.getStyling()}>
    <h2>Appeal Summary</h2>
    <ul className="appeal-summary-ul">
      {this.getListElements()}
    </ul>
    <h2>Issues</h2>
    <QueueIssueList
      appeal={_.pick(this.props.appeal.attributes, 'issues')}
      className="task-list"
      formatLevelsInNewLine
      displayIssueProgram
      displayLabels />
  </div>;
}

AppealSummary.propTypes = {
  appeal: PropTypes.object.isRequired
};
