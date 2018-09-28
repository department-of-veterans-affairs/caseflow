// @flow
import * as React from 'react';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Tooltip from '../components/Tooltip';

import COPY from '../../COPY.json';
import StringUtil from '../util/StringUtil';
import { DateString } from '../util/DateUtil';

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

export default class CaseHearingsDetail extends React.PureComponent<Props> {
  getHearingAttrs = (hearing: Hearing): Array<Object> => {
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
        {hearing.viewedByJudge &&
        <Tooltip id="hearing-worksheet-tip" text={COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_TOOLTIP}>
          <Link rel="noopener" target="_blank" href={`/hearings/${hearing.id}/worksheet/print?keep_open=true`}>
            {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
          </Link>
        </Tooltip>}
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
      value: hearing.heldBy
    }]);
  }

  getHearingInfo = () => {
    const {
      appeal: { hearings }
    } = this.props;
    const orderedHearings = _.orderBy(hearings, 'date', 'asc');
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

  getDetailField = (
    { label, valueFunction, value }: { label: string, valueFunction: Function, value?: string}
  ) => () => <React.Fragment>
    {label && <span {...boldText}>{label}:</span>} {value || valueFunction()}
  </React.Fragment>;

  render = () => {
    const {
      appeal: {
        hearings,
        appealIdsWithHearings
      }
    } = this.props;

    const listElements = [{
      label: hearings.length > 1 ? 'Hearings (Oldest to Newest)' : '',
      valueFunction: this.getHearingInfo
    }];

    return <React.Fragment>
      {Boolean(appealIdsWithHearings.length) && <React.Fragment>
        {/* todo: move to COPY */}
        This vet has other appeals with hearings. Click View All Cases at top.
      </React.Fragment>}
      <BareList
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
        })} />
    </React.Fragment>;
  };
}
