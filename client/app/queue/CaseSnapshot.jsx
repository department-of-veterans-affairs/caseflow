// @flow
import { css } from 'glamor';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';

import {
  appealWithDetailSelector,
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector,
  incompleteOrganizationTasksByAssigneeIdSelector
} from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import AttorneyActionsDropdown from './components/AttorneyActionsDropdown';
import JudgeActionsDropdown from './components/JudgeActionsDropdown';
import ColocatedActionsDropdown from './components/ColocatedActionsDropdown';
import GenericTaskActionsDropdown from './components/GenericTaskActionsDropdown';

import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import { COLORS } from '../constants/AppConstants';

import { renderLegacyAppealType } from './utils';
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

const headingStyling = css({
  marginBottom: '0.5rem'
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
  taskAssignedToUser: Task,
  taskAssignedToAttorney: Task,
  taskAssignedToOrganization: Task
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.taskAssignedToUser) {
      const today = moment();
      const dateAssigned = moment(this.props.taskAssignedToUser.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt><dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  taskAssignmentListItems = () => {
    const {
      userRole,
      taskAssignedToUser
    } = this.props;

    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.locationCode}</dd>
    </React.Fragment>;

    if (!taskAssignedToUser) {
      return assignedToListItem;
    }

    if ([USER_ROLE_TYPES.judge, USER_ROLE_TYPES.colocated].includes(userRole)) {
      const assignedByFirstName = taskAssignedToUser.assignedBy.firstName;
      const assignedByLastName = taskAssignedToUser.assignedBy.lastName;

      if (!assignedByFirstName ||
          !assignedByLastName ||
          (userRole === USER_ROLE_TYPES.judge && !taskAssignedToUser.documentId)) {
        return assignedToListItem;
      }

      const firstInitial = String.fromCodePoint(assignedByFirstName.codePointAt(0));
      const nameAbbrev = `${firstInitial}. ${assignedByLastName}`;

      if (userRole === USER_ROLE_TYPES.judge) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{nameAbbrev}</dd>
          <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt><dd>{taskAssignedToUser.documentId}</dd>
        </React.Fragment>;
      } else if (userRole === USER_ROLE_TYPES.colocated) {
        return <React.Fragment>
          <dt>{COPY.CASE_SNAPSHOT_TASK_TYPE_LABEL}</dt><dd>{CO_LOCATED_ADMIN_ACTIONS[taskAssignedToUser.action]}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_FROM_LABEL}</dt><dd>{nameAbbrev}</dd>
          <dt>{COPY.CASE_SNAPSHOT_TASK_INSTRUCTIONS_LABEL}</dt><dd>{taskAssignedToUser.instructions}</dd>
        </React.Fragment>;
      }
    }

    return <React.Fragment>
      { taskAssignedToUser.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{taskAssignedToUser.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={taskAssignedToUser.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={taskAssignedToUser.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = () => {
    if (this.props.hideDropdown) {
      return false;
    }
    if (this.props.taskAssignedToUser) {
      return true;
    }
    if (this.props.taskAssignedToAttorney) {
      return true;
    }
    if (this.props.taskAssignedToOrganization && this.props.taskAssignedToOrganization.assignedTo.type !== 'Vso') {
      return true;
    }

    return false;
  }

  render = () => {
    const {
      appeal,
      userRole
    } = this.props;
    let CheckoutDropdown = <React.Fragment />;
    const dropdownArgs = { appealId: appeal.externalId };

    if (userRole === USER_ROLE_TYPES.attorney) {
      CheckoutDropdown = <AttorneyActionsDropdown {...dropdownArgs} />;
    } else if (userRole === USER_ROLE_TYPES.judge && this.props.featureToggles.judge_case_review_checkout) {
      CheckoutDropdown = <JudgeActionsDropdown {...dropdownArgs} />;
    } else if (userRole === USER_ROLE_TYPES.colocated) {
      CheckoutDropdown = <ColocatedActionsDropdown {...dropdownArgs} />;
    } else {
      CheckoutDropdown = <GenericTaskActionsDropdown {...dropdownArgs} />;
    }

    return <div className="usa-grid" {...snapshotParentContainerStyling} {...snapshotChildResponsiveWrapFixStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</dt>
          <dd>{renderLegacyAppealType({
            aod: appeal.isAdvancedOnDocket,
            type: appeal.caseType
          })}</dd>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
          <dd>{appeal.docketNumber}</dd>
          {this.daysSinceTaskAssignmentListItem()}
        </CaseDetailsDescriptionList>
      </div>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          {this.taskAssignmentListItems()}
        </CaseDetailsDescriptionList>
      </div>
      {this.showActionsSection() &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          {CheckoutDropdown}
        </div>
      }
    </div>;
  };
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { featureToggles, userRole } = state.ui;

  return {
    appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
    featureToggles,
    userRole,
    taskAssignedToUser: tasksForAppealAssignedToUserSelector(state, { appealId: ownProps.appealId })[0],
    taskAssignedToAttorney: tasksForAppealAssignedToAttorneySelector(state, { appealId: ownProps.appealId })[0],
    taskAssignedToOrganization: incompleteOrganizationTasksByAssigneeIdSelector(state,
      { appealId: ownProps.appealId })[0]
  };
};

export default connect(mapStateToProps)(CaseSnapshot);
