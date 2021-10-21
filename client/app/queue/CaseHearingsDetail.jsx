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
import { pencilSymbol } from '../components/RenderFunctions';
import Button from '../components/Button';

import EditUnscheduledNotesModal from '../hearings/components/EditUnscheduledNotesModal';
import { UnscheduledNotes } from '../hearings/components/UnscheduledNotes';

import COPY from '../../COPY';
import { DateString } from '../util/DateUtil';
import { showVeteranCaseList } from './uiReducer/uiActions';
import { dispositionLabel } from '../hearings/utils';

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
  constructor(props) {
    super(props);

    this.state = {
      modalOpen: false,
      selectedTask: null
    };
  }

  getHearingAttrs = (hearing, userIsVsoEmployee) => {
    const hearingAttrs = [{
      label: 'Type',
      value: hearing.isVirtual ? 'Virtual' : hearing.type
    },
    {
      label: 'Disposition',
      value: <React.Fragment>
        {dispositionLabel(hearing?.disposition)}
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
        },
        {
          label: 'Judge',
          value: hearing.heldBy
        }
      );
    }

    hearingAttrs.push(
      {
        label: 'Date',
        value: <DateString date={hearing.date} dateFormat="M/D/YY" style={marginRight} />
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
    const orderedHearings = _.orderBy(hearings, 'createdAt', 'desc');
    const uniqueOrderedHearings = _.uniqWith(orderedHearings, _.isEqual);

    if (orderedHearings.length > 1) {
      _.extend(hearingElementsStyle, marginLeft);
    }

    const hearingsLength = uniqueOrderedHearings.length;
    const hearingElements = _.map(uniqueOrderedHearings, (hearing) => <div
      key={hearing.externalId} {...hearingElementsStyle}
    >
      <span {...boldText}>Hearing{hearingsLength > 1 ?
        ` ${hearingsLength - (uniqueOrderedHearings.indexOf(hearing))}` : ''}:</span>
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

  openModal = (task) => this.setState({ modalOpen: true, selectedTask: task })

  closeModal = () => this.setState({ modalOpen: false, selectedTask: null })

  getUnscheduledHearingAttrs = (task, appeal) => {
    return [
      {
        label: 'Type',
        value: appeal?.readableHearingRequestType
      },
      {
        label: 'Notes',
        value: <React.Fragment>
          <Button styling={css({ padding: 0 })} linkStyling onClick={() => this.openModal(task)} >
            <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
            <span {...css({ marginLeft: '24px' })}>Edit</span>
          </Button>
          <br />
          {task?.unscheduledHearingNotes?.notes && <UnscheduledNotes
            readonly
            styling={{ marginLeft: '2rem' }}
            unscheduledNotes={task?.unscheduledHearingNotes?.notes}
            updatedAt={task?.unscheduledHearingNotes?.updatedAt}
            updatedByCssId={task?.unscheduledHearingNotes?.updatedByCssId}
            uniqueId={task?.taskId} />
          }
        </React.Fragment>
      },
    ];
  }

  getUnscheduledHearingElements = () => {
    const {
      appeal,
      hearingTasks
    } = this.props;

    return hearingTasks.map((task, index) => <div
      key={task.taskId} {...hearingsListStyling} {...css({ marginTop: '1em' })}
    >
      <span {...boldText}>{COPY.UNSCHEDULED_HEARING_TITLE}{hearingTasks.length > 1 ?
        ` ${index + 1}` : ''}:</span>
      <BareList compact
        listStyle={css(marginLeft, noTopBottomMargin)}
        ListElementComponent="ul"
        items={this.getUnscheduledHearingAttrs(task, appeal).map(this.getDetailField)} />
    </div>);
  }

  render = () => {
    const {
      appeal: {
        caseType,
        hearings,
        completedHearingOnPreviousAppeal,
      },
      hearingTasks
    } = this.props;

    const hearingsListElements = [{
      label: hearings.length > 1 ? COPY.CASE_DETAILS_HEARING_LIST_LABEL : '',
      valueFunction: this.getHearingInfo
    }];

    return (
      <div id="hearing-details">
        {caseType === LEGACY_APPEAL_TYPES.POST_REMAND && completedHearingOnPreviousAppeal &&
          <React.Fragment>
            {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL}&nbsp;
            <a href="#" onClick={this.scrollToCaseList}>
              {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_LINK}
            </a>
            {COPY.CASE_DETAILS_HEARING_ON_OTHER_APPEAL_POST_LINK}
          </React.Fragment>
        }
        {!_.isEmpty(hearingTasks) && this.getUnscheduledHearingElements()}
        {!_.isEmpty(hearings) &&
          <BareList
            ListElementComponent="ul"
            items={hearingsListElements.map(this.getDetailField)}
            listStyle={hearingsListStyling}
          />
        }
        {this.state.modalOpen && this.state.selectedTask &&
          <EditUnscheduledNotesModal
            task={this.state.selectedTask}
            appeal={this.props.appeal}
            onCancel={this.closeModal}
          />
        }
      </div>
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
  userIsVsoEmployee: PropTypes.bool,
  hearingTasks: PropTypes.array
};

const mapStateToProps = (state) => {
  return { userIsVsoEmployee: state.ui.userIsVsoEmployee };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showVeteranCaseList
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(CaseHearingsDetail));
