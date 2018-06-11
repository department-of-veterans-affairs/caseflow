import { after, css, merge } from 'glamor';
import moment from 'moment';
import PropTypes from 'prop-types';
import React from 'react';

import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import COPY from '../../COPY.json';
import { USER_ROLES } from './constants';
import { COLORS } from '../constants/AppConstants';
import { renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';

const snapshotParentContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'flex',
  lineHeight: '3rem',
  marginTop: '3rem',
  padding: '2rem 0',
  '& > div': { padding: '0 3rem 0 0' },
  '& > div:not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  '& > div:first-child': { paddingLeft: '3rem' },

  '& .Select': { maxWidth: '100%' }
});

const definitionListStyling = css({
  margin: '0',
  '& dt': merge(
    after({ content: ':' }),
    {
      float: 'left',
      fontSize: '1.5rem',
      marginRight: '0.5rem'
    }
  )
});

const aboutListStyling = css({
  '& dt': {
    color: COLORS.GREY_MEDIUM,
    textTransform: 'uppercase'
  }
});

const assignmentListStyling = css({
  '& dt': { fontWeight: 'bold' }
});

const aboutHeadingStyling = css({
  marginBottom: '0.5rem'
});

export default class CaseSnapshot extends React.PureComponent {
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
    return <div className="usa-grid" {...snapshotParentContainerStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...aboutHeadingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <dl {...definitionListStyling} {...aboutListStyling}>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</dt>
          <dd>{renderAppealType(this.props.appeal)}</dd>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
          <dd>{this.props.appeal.attributes.docket_number}</dd>
          {this.daysSinceTaskAssignmentListItem()}
        </dl>
      </div>
      <div className="usa-width-one-fourth">
        <dl {...definitionListStyling} {...assignmentListStyling}>
          {this.taskAssignmentListItems()}
        </dl>
      </div>
      { this.props.featureToggles.phase_two &&
        this.props.loadedQueueAppealIds.includes(this.props.appeal.attributes.vacols_id) &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          <SelectCheckoutFlowDropdown vacolsId={this.props.appeal.attributes.vacols_id} />
        </div>
      }
    </div>;
  };
}

CaseSnapshot.propTypes = {
  appeal: PropTypes.object.isRequired,
  featureToggles: PropTypes.object,
  loadedQueueAppealIds: PropTypes.array,
  task: PropTypes.object,
  userRole: PropTypes.string
};
