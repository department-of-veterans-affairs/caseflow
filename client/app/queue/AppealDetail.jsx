import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from '../reader/IssueList';
import { boldText } from './constants';
import StringUtil from '../util/StringUtil';
import { dateString } from './utils';

const appealDetailStyling = css({
  '> .appeal-summary-ul': {
    paddingLeft: 0,
    listStyle: 'none'
  },
  '& .task-list': {
    paddingLeft: '1.5rem',
    '& li': {
      marginTop: '2rem'
    }
  }
});

export default class AppealDetail extends React.PureComponent {
  getAppealAttr = (attr) => _.get(this.props.appeal.attributes, attr);

  getLastHearing = () => {
    const hearings = this.getAppealAttr('hearings');

    if (!hearings.length) {
      return {};
    }

    return _.orderBy(hearings, 'held_on', 'desc')[0];
  };

  getListElements = () => {
    const listElements = [{
      label: 'Type',
      valueFunction: () => this.getAppealAttr('type')
    }, {
      label: 'Power of Attorney',
      valueFunction: () => this.getAppealAttr('power_of_attorney')
    }];

    if (this.getAppealAttr('hearings').length) {
      const lastHearing = this.getLastHearing();

      listElements.concat([{
        label: 'Hearing Preference',
        valueFunction: () => StringUtil.snakeCaseToCapitalized(lastHearing.type)
      }, {
        label: 'Hearing held',
        valueFunction: () => dateString(lastHearing.held_on, 'M/D/YY')
      }, {
        label: 'Judge at hearing',
        valueFunction: () => lastHearing.held_by
      }]);
    }

    listElements.push({
      label: 'Regional Office',
      valueFunction: () => {
        const {
          city,
          key
        } = this.getAppealAttr('regional_office');

        return `${city} (${key.replace('RO', '')})`;
      }
    });

    return listElements.map(({ label, valueFunction }, idx) => <li key={`appeal-summary-${idx}`}>
      <span {...boldText}>{label}:</span> {valueFunction()}
    </li>);
  };

  render = () => <div {...appealDetailStyling}>
    <h2>Appeal Summary</h2>
    <ul className="appeal-summary-ul">
      {this.getListElements()}
    </ul>
    <h2>Issues</h2>
    <IssueList
      appeal={_.pick(this.props.appeal.attributes, 'issues')}
      className="task-list"
      formatLevelsInNewLine
      displayIssueProgram
      displayIssueNote
      displayLabels />
  </div>;
}

AppealDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
