import { css } from 'glamor';
import moment from 'moment';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import { appealsByAssigneeCssIdSelector } from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import JudgeStartCheckoutFlowDropdown from './components/JudgeStartCheckoutFlowDropdown';
import COPY from '../../COPY.json';
import { USER_ROLES } from './constants';
import { COLORS } from '../constants/AppConstants';
import { renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';

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

export class CaseSnapshot extends React.PureComponent {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.task) {
      const today = moment();
      const dateAssigned = moment(this.props.task.attributes.assigned_on);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt><dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  taskAssignmentListItems = () => {
    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.attributes.location_code}</dd>
    </React.Fragment>;

    if (!this.props.task) {
      return assignedToListItem;
    }

    const task = this.props.task.attributes;

    if (this.props.userRole === USER_ROLES.JUDGE) {
      if (!task.assigned_by_first_name || !task.assigned_by_last_name || !task.document_id) {
        return assignedToListItem;
      }

      const firstInitial = String.fromCodePoint(task.assigned_by_first_name.codePointAt(0));
      const nameAbbrev = `${firstInitial}. ${task.assigned_by_last_name}`;

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{nameAbbrev}</dd>
        <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt><dd>{task.document_id}</dd>
      </React.Fragment>;
    }

    return <React.Fragment>
      { task.added_by_name && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{task.added_by_name}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assigned_on} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={task.due_on} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  render = () => {
    const {
      appeal: { attributes: appeal }
    } = this.props;
    let CheckoutDropdown = <React.Fragment />;

    if (this.props.userRole === USER_ROLES.ATTORNEY) {
      CheckoutDropdown = <SelectCheckoutFlowDropdown appealId={appeal.vacols_id} />;
    } else if (this.props.featureToggles.judge_case_review_checkout) {
      CheckoutDropdown = <JudgeStartCheckoutFlowDropdown appealId={appeal.vacols_id} />;
    }

    return <div className="usa-grid" {...snapshotParentContainerStyling} {...snapshotChildResponsiveWrapFixStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</dt>
          <dd>{renderAppealType(this.props.appeal)}</dd>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
          <dd>{appeal.docket_number}</dd>
          {this.daysSinceTaskAssignmentListItem()}
        </CaseDetailsDescriptionList>
      </div>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          {this.taskAssignmentListItems()}
        </CaseDetailsDescriptionList>
      </div>
      {!this.props.hideDropdown &&
        this.props.appealsAssignedToCurrentUser.includes(appeal.vacols_id) &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          {CheckoutDropdown}
        </div>
      }
    </div>;
  };
}

CaseSnapshot.propTypes = {
  appeal: PropTypes.object.isRequired,
  featureToggles: PropTypes.object,
  appealsAssignedToCurrentUser: PropTypes.array,
  task: PropTypes.object,
  userRole: PropTypes.string,
  hideDropdown: PropTypes.bool
};

const mapStateToProps = (state) => ({
  ..._.pick(state.ui, 'featureToggles', 'userRole'),
  appealsAssignedToCurrentUser: Object.keys(appealsByAssigneeCssIdSelector(state))
});

export default connect(mapStateToProps)(CaseSnapshot);
