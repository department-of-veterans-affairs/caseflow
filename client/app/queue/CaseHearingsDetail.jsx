// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import {
  boldText,
  LEGACY_APPEAL_TYPES
} from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Tooltip from '../components/Tooltip';

import COPY from '../../COPY.json';
import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';
import { showVeteranCaseList } from './uiReducer/uiActions';

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

import type {
  Appeal,
  Hearing
} from './types/models';

type Props = {|
  appeal: Appeal,
|};

type Params = Props & {|
  showVeteranCaseList: typeof showVeteranCaseList
|}

class CaseHearingsDetail extends React.PureComponent<Params> {
  getHearingAttrs = (hearing: Hearing): Array<Object> => {
    return [{
      label: 'Type',
      value: StringUtil.snakeCaseToCapitalized(hearing.type)
    },
    {
      label: 'Disposition',
      value: <React.Fragment>
        {hearing.disposition && StringUtil.snakeCaseToCapitalized(hearing.disposition)}&nbsp;&nbsp;
        {hearing.viewedByJudge &&
        <Tooltip id="hearing-worksheet-tip" text={COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_TOOLTIP}>
          <Link rel="noopener" target="_blank" href={`/hearings/${hearing.externalId}/worksheet/print?keep_open=true`}>
            {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
          </Link>
        </Tooltip>}
      </React.Fragment>
    },
    {
      label: 'Date',
      value: <DateString date={hearing.date} dateFormat="M/D/YY" style={marginRight} />
    }, {
      label: 'Judge',
      value: hearing.heldBy
    }
    ];
  }

  getHearingInfo = () => {
    const {
      appeal: { hearings }
    } = this.props;
    const orderedHearings = _.orderBy(hearings, 'date', 'asc');
    const uniqueOrderedHearings = _.uniqWith(orderedHearings, _.isEqual);
    const hearingElementsStyle = css({
      '&:first-of-type': {
        marginTop: '1rem'
      }
    });

    if (orderedHearings.length > 1) {
      _.extend(hearingElementsStyle, marginLeft);
    }

    const hearingElements = _.map(uniqueOrderedHearings, (hearing) => <div
      key={hearing.externalId} {...hearingElementsStyle}
    >
      <span {...boldText}>Hearing{uniqueOrderedHearings.length > 1 ?
        ` ${uniqueOrderedHearings.indexOf(hearing) + 1}` : ''}:</span>
      <BareList compact
        listStyle={css(marginLeft, noTopBottomMargin)}
        ListElementComponent="ul"
        items={this.getHearingAttrs(hearing).map(this.getDetailField)} />
    </div>);

    return <React.Fragment>
      {uniqueOrderedHearings.length > 1 && <br />}
      {hearingElements}
    </React.Fragment>;
  }

  getDetailField = (
    { label, valueFunction, value }: { label: string, valueFunction: Function, value?: string}
  ) => () => <React.Fragment>
    {label && <span {...boldText}>{label}:</span>} {typeof value === 'undefined' ? valueFunction() : value}
  </React.Fragment>;

  scrollToCaseList = () => {
    window.scroll({
      top: 0,
      left: 0,
      behavior: 'smooth'
    });
    this.props.showVeteranCaseList();
  }

  render = () => {
    const {
      appeal: {
        caseType,
        hearings,
        completedHearingOnPreviousAppeal
      }
    } = this.props;

    const listElements = [{
      label: hearings.length > 1 ? COPY.CASE_DETAILS_HEARING_LIST_LABEL : '',
      valueFunction: this.getHearingInfo
    }];

    return <React.Fragment>
      {caseType === LEGACY_APPEAL_TYPES.POST_REMAND && completedHearingOnPreviousAppeal && <React.Fragment>
        {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL}&nbsp;
        <a href="#" onClick={this.scrollToCaseList}>{COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_LINK}</a>
        {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_POST_LINK}
      </React.Fragment>}
      {Boolean(hearings.length) && <BareList
        ListElementComponent="ul"
        items={listElements.map(this.getDetailField)}
        listStyle={css(appealSummaryUlStyling, {
          '> li': {
            paddingBottom: '1.5rem',
            paddingTop: '1rem',
            borderBottom: '1px solid grey'
          },
          '> li:last-child': {
            borderBottom: 0
          }
        })} />}
    </React.Fragment>;
  };
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showVeteranCaseList
}, dispatch);

export default (connect(null, mapDispatchToProps)(CaseHearingsDetail): React.ComponentType<Props>);
