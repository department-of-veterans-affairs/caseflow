// @flow
import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import {
  actionableTasksForAppeal,
  appealWithDetailSelector
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import DocketTypeBadge from './components/DocketTypeBadge';
import ActionsDropdown from './components/ActionsDropdown';
import OnHoldLabel from './components/OnHoldLabel';
import CopyTextButton from '../components/CopyTextButton';
import TextField from '../components/TextField';
import ReaderLink from './ReaderLink';
import { CATEGORIES } from './constants';
import { toggleVeteranCaseList } from './uiReducer/uiActions';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';
import StringUtil from '../util/StringUtil';
import type { Dispatch } from './types/state';

import {
  renderLegacyAppealType,
  taskIsOnHold
} from './utils';
import { DateString } from '../util/DateUtil';
import type { Appeal, Task } from './types/models';
import type { State } from './types/state';

const snapshotParentContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'flex',
  flexWrap: 'wrap',
  lineHeight: '3rem',
  marginTop: '3rem',
  padding: '2rem 0',
  '& > div': { padding: '0 3rem 0 0' },
  '& > div:not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  '& > div:first-child': { paddingLeft: '3rem' },

  '& .Select': { maxWidth: '100%' }
});

const containingDivStyling = css({
  /*borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
  display: 'block',
  // Offsets the padding from .cf-app-segment--alt to make the bottom border full width.
  margin: '-2rem -4rem 0 -4rem',
  padding: '0 0 1.5rem 4rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }*/
});

const listStyling = css({
  listStyleType: 'none',
  /*verticalAlign: 'super',
  padding: '1rem 0 0 0'*/
});

const listItemStyling = css({
  /*display: 'inline',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }*/
});

const headingStyling = css({
  marginBottom: '0.5rem'
});

const newStyling = css({
  margin: '100px 200px 100px 0px'
});

const spanStyle = css({
  border: '2px',
  borderStyle: 'solid',
  borderColor: '#DCDCDC',
  padding: '5px',
  backgroundColor: 'white'
});

const titleStyle = css({
  fontWeight: 'bold',
  textAlign: 'center'
});

const divStyle = css({
  marginRight: '10px'
});

const redType = css({
  color: 'red'
});

const displayNone = css({
  display: 'none'
});

const editButton = css({
  float: 'right'
});

const caseInfo = css({
  backgroundColor: '#F8F8F8'
});


const snapshotChildResponsiveWrapFixStyling = css({
  '@media(max-width: 1200px)': {
    '& > .usa-width-one-half': {
      borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
      margin: '2rem 3rem 0 3rem',
      marginRight: '3rem !important',
      paddingTop: '2rem',
      width: '100%'
    },
    '& > div:nth-child(2)': { borderRight: 'none' }
  }
});

type Params = {|
  appealId: string,
  hideDropdown?: boolean
|};

type Props = Params & {|
  featureToggles: Object,
  userRole: string,
  appeal: Appeal,
  primaryTask: Task,
  taskAssignedToUser: Task,
  canEditAod: Boolean
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.primaryTask) {
      const today = moment().startOf('day');
      const dateAssigned = moment(this.props.primaryTask.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt><dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  getAbbrevName = ({ firstName, lastName } : { firstName: string, lastName: string }) => {
    return `${firstName.substring(0, 1)}. ${lastName}`;
  }

  getActionName = () => {
    const {
      label
    } = this.props.primaryTask;

    // First see if there is a constant to convert the label, otherwise sentence-ify it
    if (CO_LOCATED_ADMIN_ACTIONS[label]) {
      return CO_LOCATED_ADMIN_ACTIONS[label];
    }

    return StringUtil.snakeCaseToSentence(label);
  }

  taskInstructionsWithLineBreaks = (instructions?: Array<string>) => <React.Fragment>
    {instructions && instructions.map((text, i) => <React.Fragment><span key={i}>{text}</span><br /></React.Fragment>)}
  </React.Fragment>;

  taskInformation = () => {
    const {
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return null;
    }

    const assignedByAbbrev = primaryTask.assignedBy.firstName ?
      this.getAbbrevName(primaryTask.assignedBy) : null;

    const preparedByAbbrev = primaryTask.decisionPreparedBy ?
      this.getAbbrevName(primaryTask.decisionPreparedBy) : null;

    return <React.Fragment>
      { primaryTask.label &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{this.getActionName()}</dd>
        </React.Fragment> }
      { assignedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment> }
      { taskIsOnHold(primaryTask) &&
        <React.Fragment>
          <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
          <dd><OnHoldLabel task={primaryTask} /></dd>
        </React.Fragment>
      }
      { primaryTask.instructions &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(primaryTask.instructions)}</dd>
        </React.Fragment> }
      { preparedByAbbrev &&
        <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{preparedByAbbrev}</dd>
        </React.Fragment> }
    </React.Fragment>;
  }

  legacyTaskInformation = () => {
    // If this is not a task attached to a legacy appeal, use taskInformation.
    if (!this.props.appeal.isLegacyAppeal) {
      return this.taskInformation();
    }

    const {
      userRole,
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return null;
    }

    const assignedByAbbrev = primaryTask.assignedBy.firstName ?
      this.getAbbrevName(primaryTask.assignedBy) : null;

    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    // TODO: Can we ever exucute this block? Doesn't the exact same condition above kick us out of this function
    // before we ever reach this point?
    if (!primaryTask) {
      return assignedToListItem;
    }

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = primaryTask.assignedBy.firstName;
      const assignedByLastName = primaryTask.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !primaryTask.documentId)) {
        return assignedToListItem;
      }

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{assignedByAbbrev}</dd>
        </React.Fragment>;
      } else if (userRole === USER_ROLE_TYPES.colocated) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[primaryTask.label]}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{assignedByAbbrev}</dd>
          { taskIsOnHold(primaryTask) &&
            <React.Fragment>
              <dt>{COPY.CASE_LIST_TABLE_TASK_DAYS_ON_HOLD_COLUMN_TITLE}</dt>
              <dd><OnHoldLabel task={primaryTask} /></dd>
            </React.Fragment>
          }
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt>
          <dd>{this.taskInstructionsWithLineBreaks(primaryTask.instructions)}</dd>
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      { primaryTask.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{primaryTask.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={primaryTask.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={primaryTask.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = (): boolean => {
    if (this.props.hideDropdown) {
      return false;
    }

    const {
      userRole,
      primaryTask
    } = this.props;

    if (!primaryTask) {
      return false;
    }

    // users can end up at case details for appeals with no DAS
    // record (!task.taskId). prevent starting attorney checkout flows
    return userRole === USER_ROLE_TYPES.judge ? Boolean(primaryTask) : Boolean(primaryTask.taskId);
  }

  render = () => {
    const {
      appeal,
      primaryTask,
      veteranCaseListIsVisible
    } = this.props;
    const taskAssignedToVso = primaryTask && primaryTask.assignedTo.type === 'Vso';

    console.log('--test--');
    console.log(appeal);
    console.log(this.props);

    return <CaseSnapshotScaffolding className="usa-grid" {...snapshotParentContainerStyling}>
      {/*<div className="usa-grid" {...snapshotParentContainerStyling}>*/}

      {
        /*<div {...newStyling}>
        <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
        <TextField text={appeal.docketNumber} value={appeal.docketNumber} readOnly={true} />
        <dd><DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}</dd>
      </div>*/
      }

      <React.Fragment>
        <span {...titleStyle}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL.toUpperCase()}</span>
        <span {...spanStyle}>
          <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />{appeal.docketNumber}
        </span>
      </React.Fragment>

      <React.Fragment>
        <span {...titleStyle}>{'VETERAN DOCUMENTS'}</span>
        <span>
          <ReaderLink appealId={appeal.id} appeal={appeal} redirectUrl={window.location.pathname} longMessage />
        </span>
      </React.Fragment>

      <React.Fragment>
        <span {...titleStyle}>{'TYPE'}</span>
        <span {...redType}>{'CAVC'}</span>
        <span className={appeal.caseType == 'CAVC' ? redType : null}>{appeal.caseType}</span>
      </React.Fragment>

      <React.Fragment>
        <span {...divStyle} className={primaryTask && primaryTask.documentId ? null : displayNone}>
         <span {...titleStyle}>{'DECISION DOCUMENT ID'}</span>
         <CopyTextButton text={primaryTask ? primaryTask.documentId : null} />
        </span>
      </React.Fragment>

      <React.Fragment>
        <Link onClick={this.props.toggleVeteranCaseList}>
          { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
        </Link>
      </React.Fragment>

      {/*
        <span>
          <Link onClick={this.props.toggleVeteranCaseList}>
            { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
          </Link>
        </span>*/
      }

    {/* </div> */}
    </CaseSnapshotScaffolding>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole, canEditAod } = state.ui;
  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    primaryTask: actionableTasksForAppeal(state, { appealId: ownProps.appealId })[0],
    canEditAod,
    veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseSnapshot);

const CaseSnapshotScaffolding = (props) => <div {...caseInfo}>
  {props.children.map((child, i) => child && <span key={i}>{child}</span>)}
</div>;
