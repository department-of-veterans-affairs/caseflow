import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import IssueList from './components/IssueList';
import BareList from '../components/BareList';
import { boldText, TASK_ACTIONS } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';

const appealSummaryUlStyling = css({
  paddingLeft: 0,
  listStyle: 'none'
});
const marginRight = css({ marginRight: '1rem' });
const marginLeft = css({ marginLeft: '2rem' });
const noTopBottomMargin = css({
  marginTop: 0,
  marginBottom: '1rem'
});

export default class AppealDetail extends React.PureComponent {
  getAppealAttr = (attr) => _.get(this.props.appeal.attributes, attr);

  getHearingAttrs = (hearing) => {
    const listElements = [{
      label: 'Type',
      value: StringUtil.snakeCaseToCapitalized(hearing.type)
    }];

    if (_.isNull(hearing.disposition)) {
      return listElements;
    }

    listElements.push({
      label: 'Disposition',
      value: <React.Fragment>
        {StringUtil.snakeCaseToCapitalized(hearing.disposition)}&nbsp;&nbsp;
        <Link rel="noopener" target="_blank" href={`/hearings/${hearing.id}/worksheet/print`}>
          View Hearing Worksheet
        </Link>
      </React.Fragment>
    });

    if (hearing.disposition === 'cancelled') {
      return listElements;
    }

    return listElements.concat([{
      label: 'Date',
      value: <DateString date={hearing.date} dateFormat="M/D/YY" style={marginRight} />
    }, {
      label: 'Judge',
      value: hearing.held_by
    }]);
  }

  getHearingInfo = () => {
    const orderedHearings = _.orderBy(this.getAppealAttr('hearings'), 'date', 'asc');
    const hearingElementsStyle = css({
      '&:first-of-type': {
        marginTop: '1rem'
      }
    });

    if (orderedHearings.length > 1) {
      _.extend(hearingElementsStyle, marginLeft);
    }

    const hearingElements = _.map(orderedHearings, (hearing) => <div key={hearing.id} {...hearingElementsStyle}>
      <span {...boldText}>Hearing{orderedHearings.length > 1 ? ` ${orderedHearings.indexOf(hearing) + 1}` : ''}:</span>
      <BareList compact
        listStyle={css(marginLeft, noTopBottomMargin)}
        ListElementComponent="ul"
        items={this.getHearingAttrs(hearing).map(this.getDetailField)} />
    </div>);

    return <React.Fragment>
      {orderedHearings.length > 1 && <br />}
      {hearingElements}
    </React.Fragment>;
  }

  getDetailField = ({ label, valueFunction, value }) => () => <React.Fragment>
    {label && <span {...boldText}>{label}:</span>} {value || valueFunction()}
  </React.Fragment>;

  getListElements = () => {
    const listElements = [{
      label: 'Type(s)',
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

    if (this.getAppealAttr('hearings').length) {
      listElements.splice(2, 0, {
        label: this.getAppealAttr('hearings').length > 1 ? 'Hearings (Oldest to Newest)' : '',
        valueFunction: this.getHearingInfo
      });
    }

    return <BareList
      ListElementComponent="ul"
      items={listElements.map(this.getDetailField)}
      listStyle={css(appealSummaryUlStyling, {
        '> li': {
          paddingBottom: '1.5rem',
          paddingTop: '1rem',
          borderBottom: '1px solid grey'
        }
      })} />;
  };

  componentDidMount = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.VIEW_APPEAL_INFO);
  }

  render = () => <div>
    <h2 {...css({ marginBottom: '1rem' })}>Appeal Summary</h2>
    {this.getListElements()}
    <h2>Issues</h2>
    <IssueList appeal={_.pick(this.props.appeal.attributes, 'issues')} />
  </div>;
}

AppealDetail.propTypes = {
  analyticsSource: PropTypes.string.isRequired,
  appeal: PropTypes.object.isRequired
};
