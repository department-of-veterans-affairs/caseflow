import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from '../reader/IssueList';
import BareList from '../components/BareList';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { boldText } from './constants';
import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';

const appealSummaryUlStyling = css({
  paddingLeft: 0,
  listStyle: 'none'
});
const marginRight = css({ marginRight: '1rem' });

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
        value: <React.Fragment>
          <DateString date={lastHearing.held_on} dateFormat="M/D/YY" style={marginRight} />
          <Link target="_blank" href={`/hearings/${lastHearing.id}/worksheet`}>View Hearing Worksheet</Link>
        </React.Fragment>
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
