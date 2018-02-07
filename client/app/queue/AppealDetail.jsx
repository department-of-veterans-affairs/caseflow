import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from '../reader/IssueList';
import BareList from '../components/BareList';
import { boldText, CATEGORIES, TASK_ACTIONS, INTERACTION_TYPES } from './constants';
import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';

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
      value: this.getAppealAttr('type')
    }, {
      label: 'Power of Attorney',
      value: this.getAppealAttr('power_of_attorney')
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
        value: StringUtil.snakeCaseToCapitalized(lastHearing.type)
      }, {
        label: 'Hearing held',
        value: <DateString date={lastHearing.held_on} dateFormat="M/D/YY" />
      }, {
        label: 'Judge at hearing',
        value: lastHearing.held_by
      }]);
    }

    const getDetailField = ({ label, valueFunction, value }) => () => <React.Fragment>
      <span {...boldText}>{label}:</span> {value || valueFunction()}
    </React.Fragment>;

    return <BareList ListElementComponent="ul" items={listElements.map(getDetailField)} />;
  };

  componentDidMount() {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPEAL_INFO);
  }

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
