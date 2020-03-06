import * as React from 'react';
import PropTypes from 'prop-types';
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

import COPY from '../../COPY';
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
const hearingsListStyling = css(appealSummaryUlStyling, {
  '> li': {
    paddingBottom: '1.5rem',
    paddingTop: '1rem',
    borderBottom: '1px solid grey'
  },
  '> li:last-child': {
    borderBottom: 0
  }
});
const hearingElementsStyle = css({
  '&:first-of-type': {
    marginTop: '1rem'
  }
});

class CaseHearingsDetail extends React.PureComponent {
  getHearingAttrs = (hearing, userIsVsoEmployee) => {
    const hearingAttrs = [{
      label: 'Type',
      value: hearing.isVirtual ? 'Virtual' : hearing.type
    },
    {
      label: 'Disposition',
      value: <React.Fragment>
        {hearing.disposition && StringUtil.snakeCaseToCapitalized(hearing.disposition)}
      </React.Fragment>
    }];

    if (!userIsVsoEmployee) {
      hearingAttrs.push(
        {
          label: '',
          value: <Tooltip id="hearing-worksheet-tip" text={COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_TOOLTIP}>
            <Link
              rel="noopener"
              target="_blank"
              href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearing.externalId}`}>
              {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
            </Link>
          </Tooltip>
        }
      );
    }

    hearingAttrs.push(
      {
        label: 'Date',
        value: <DateString date={hearing.date} dateFormat="M/D/YY" style={marginRight} />
      },
      {
        label: 'Judge',
        value: hearing.heldBy
      }
    );

    if (!userIsVsoEmployee) {
      hearingAttrs.push(
        {
          label: '',
          value: <Link href={`/hearings/${hearing.externalId}/details`}>
            {COPY.CASE_DETAILS_HEARING_DETAILS_LINK_COPY}
          </Link>
        }
      );
    }

    return hearingAttrs;
  }

  getHearingInfo = () => {
    const {
      appeal: { hearings },
      userIsVsoEmployee
    } = this.props;
    const orderedHearings = _.orderBy(hearings, 'date', 'asc');
    const uniqueOrderedHearings = _.uniqWith(orderedHearings, _.isEqual);

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
        items={this.getHearingAttrs(hearing, userIsVsoEmployee).map(this.getDetailField)} />
    </div>);

    return <React.Fragment>
      {uniqueOrderedHearings.length > 1 && <br />}
      {hearingElements}
    </React.Fragment>;
  }

  getDetailField = (
    { label, valueFunction, value }
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

    return (
      <React.Fragment>
        {caseType === LEGACY_APPEAL_TYPES.POST_REMAND && completedHearingOnPreviousAppeal &&
          <React.Fragment>
            {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL}&nbsp;
            <a href="#" onClick={this.scrollToCaseList}>
              {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_LINK}
            </a>
            {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_POST_LINK}
          </React.Fragment>
        }
        {!_.isEmpty(hearings) &&
          <BareList
            ListElementComponent="ul"
            items={listElements.map(this.getDetailField)}
            listStyle={hearingsListStyling}
          />
        }
      </React.Fragment>
    );
  };
}

CaseHearingsDetail.propTypes = {
  appeal: PropTypes.shape({
    hearings: PropTypes.arrayOf(
      PropTypes.shape({
        externalId: PropTypes.string,
        type: PropTypes.string

      })
    ),
    caseType: PropTypes.string,
    completedHearingOnPreviousAppeal: PropTypes.bool
  }),
  showVeteranCaseList: PropTypes.func,
  userIsVsoEmployee: PropTypes.bool
};

const mapStateToProps = (state) => {
  return { userIsVsoEmployee: state.ui.userIsVsoEmployee };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showVeteranCaseList
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CaseHearingsDetail));
