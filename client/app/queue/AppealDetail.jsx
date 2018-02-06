import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from '../reader/IssueList';
import { boldText } from './constants';
import StringUtil from '../util/StringUtil';
import { dateString } from './utils';

const appealSummaryUlStyling = css({
  paddingLeft: 0,
  listStyle: 'none'
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
    }, {
      label: 'Regional Office',
      valueFunction: () => {
        const {
          city,
          key
        } = this.getAppealAttr('regional_office');

        return `${city} (${key.replace('RO', '')})`;
      }
    }];

    if (this.getAppealAttr('hearings').length) {
      const lastHearing = this.getLastHearing();

      listElements.splice(2, 0, ...[{
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

    return listElements.map(({ label, valueFunction }, idx) => <li key={`appeal-summary-${idx}`}>
      <span {...boldText}>{label}:</span> {valueFunction()}
    </li>);
  };

  render = () => <div>
    <h2>Appeal Summary</h2>
    <ul {...appealSummaryUlStyling}>
      {this.getListElements()}
    </ul>
    <h2>Issues</h2>
    <IssueList
      appeal={_.pick(this.props.appeal.attributes, 'issues')}
      formatLevelsInNewLine
      displayIssueProgram
      displayIssueNote
      spaceBetweenIssues
      leftAlignList
      displayLabels />
  </div>;
}

AppealDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
