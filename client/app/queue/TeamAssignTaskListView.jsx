import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { NavLink } from 'react-router-dom';

import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';

import {
  judgeAssignTasksSelector,
  camoAssignTasksSelector,
  getTasksByUserId
} from './selectors';
import PageRoute from '../components/PageRoute';
import AssignedCasesPage from './AssignedCasesPage';
import UnassignedCasesPage from './UnassignedCasesPage';

const containerStyles = css({
  position: 'relative'
});

/**
 * Case assignment page used by judges to request new cases and assign cases to their attorneys.
 * Also used by VHA CAMO to bulk assign to VHA Program Offices.
 * Cases to be assigned are rendered by component UnassignedCasesPage.
 * Cases that have been assigned are rendered by component AssignedCasesPage.
 */
class TeamAssignTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  render = () => {
    const { userId,
      userCssId,
      targetUserId,
      targetUserCssId,
      attorneysOfJudge,
      organizations,
      unassignedTasksCount,
      match,
      userIsCamoEmployee,
      vhaProgramOffices
    } = this.props;

    const chosenUserId = targetUserId || userId;

    return <AppSegment filledBackground styling={containerStyles}>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {unassignedTasksCount} Cases{(userCssId === targetUserCssId) ? '' : ` for ${targetUserCssId}`}</h1>
          <QueueOrganizationDropdown organizations={organizations} />
        </div>
        <div className="usa-width-one-fourth">
          <ul className="usa-sidenav-list">
            <li>
              <NavLink
                to={`/queue/${targetUserCssId}/assign${userIsCamoEmployee ? '?role=camo' : ''}`}
                activeClassName="usa-current" exact>
                Cases to Assign ({unassignedTasksCount})
              </NavLink>
            </li>
            {userIsCamoEmployee && vhaProgramOffices.data.
              map((org) => <li key={org.id}>
                <NavLink to={`/queue/${targetUserCssId}/assign/${org.id}`} activeClassName="usa-current" exact>
                  {org.attributes.name} ({org.active_task_count})
                </NavLink>
              </li>)
            }
            {attorneysOfJudge.
              map((attorney) => <li key={attorney.id}>
                <NavLink to={`/queue/${targetUserCssId}/assign/${attorney.id}`} activeClassName="usa-current" exact>
                  {attorney.full_name} ({attorney.active_task_count})
                </NavLink>
              </li>)}
          </ul>
        </div>
        <div className="usa-width-three-fourths">
          <PageRoute
            exact
            path={match.url}
            title="Cases to Assign | Caseflow"
            render={() => <UnassignedCasesPage userId={chosenUserId} />}
          />
          <PageRoute
            path={`${match.url}/:attorneyId`}
            title="Assigned Cases | Caseflow"
            component={AssignedCasesPage}
          />
        </div>
      </div>
    </AppSegment>;
  };
}

TeamAssignTaskListView.propTypes = {
  attorneysOfJudge: PropTypes.array.isRequired,
  resetSuccessMessages: PropTypes.func,
  resetSaveState: PropTypes.func,
  clearCaseSelectSearch: PropTypes.func,
  match: PropTypes.object,
  targetUserId: PropTypes.number,
  targetUserCssId: PropTypes.string,
  userCssId: PropTypes.string,
  userId: PropTypes.number,
  unassignedTasksCount: PropTypes.number,
  organizations: PropTypes.array,
  userIsCamoEmployee: PropTypes.bool,
  vhaProgramOffices: PropTypes.shape({
    data: PropTypes.array,
    error: PropTypes.object
  })
};

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge,
      vhaProgramOffices
    },
    ui: {
      userIsCamoEmployee
    }
  } = state;

  let taskSelector = judgeAssignTasksSelector(state);

  if (userIsCamoEmployee) {
    taskSelector = camoAssignTasksSelector(state);
  }

  return {
    unassignedTasksCount: taskSelector.length,
    userCssId: state.ui.userCssId,
    targetUserId: state.ui.targetUser?.id,
    targetUserCssId: state.ui.targetUser?.cssId,
    tasksByUserId: getTasksByUserId(state),
    attorneysOfJudge,
    vhaProgramOffices
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetSuccessMessages,
    resetSaveState
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(TeamAssignTaskListView);
