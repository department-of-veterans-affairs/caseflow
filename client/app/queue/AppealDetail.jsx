import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from './components/IssueList';
import BareList from '../components/BareList';
import { boldText, CATEGORIES, TASK_ACTIONS } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';

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

  getHearingInfo = () => {
    const hearing = this.getLastHearing();
    const listElements = [{
      label: 'Hearing preference',
      value: StringUtil.snakeCaseToCapitalized(hearing.type)
    }, {
      label: 'Hearing disposition',
      value: StringUtil.snakeCaseToCapitalized(hearing.disposition)
    }];

    if (hearing.disposition.includes('cancel')) {
      return listElements;
    } else {
      return listElements.concat([{
        label: 'Hearing held',
        value: <React.Fragment>
          <DateString date={hearing.held_on} dateFormat="M/D/YY" style={marginRight} />
          <Link target="_blank" href={`/hearings/${hearing.id}/worksheet`}>View Hearing Worksheet</Link>
        </React.Fragment>
      }, {
        label: 'Judge at hearing',
        value: hearing.held_by
      }]);
    }
  }

  getListElements = () => {
    const listElements = [{
      label: 'Type',
      value: renderAppealType(this.props.appeal)
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

    if (this.getLastHearing().disposition) {
      listElements.splice(2, 0, ...this.getHearingInfo());
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
    <IssueList appeal={_.pick(this.props.appeal.attributes, 'issues')} />
  </div>;
}

AppealDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
