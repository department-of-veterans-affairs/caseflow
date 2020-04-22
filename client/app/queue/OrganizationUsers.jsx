/* eslint-disable max-len */
import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ApiUtil from '../util/ApiUtil';
import Alert from '../components/Alert';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';

import { LOGO_COLORS } from '../constants/AppConstants';
import COPY from '../../COPY';
import LoadingDataDisplay from '../components/LoadingDataDisplay';

const userStyle = css({ margin: '2rem 0 3rem',
  borderBottom: '1rem solid gray',
  borderWidth: '1px' });
const topUserStyle = css({ margin: '2rem 0 2rem',
  borderTop: '1rem solid gray',
  borderWidth: '1px',
  paddingTop: '2.5rem' });
const buttonPaddingStyle = css({ marginRight: '1rem',
  display: 'inline-block',
  height: '6rem' });

export default class OrganizationUsers extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      organizationName: null,
      judgeTeam: null,
      organizationUsers: [],
      remainingUsers: [],
      loading: true,
      error: null,
      addingUser: null,
      removingUser: {},
      changingAdminRights: {},
      changingDecisionDrafting: {}
    };
  }

  loadingPromise = () => {
    return ApiUtil.get(`/organizations/${this.props.organization}/users`).then((response) => {
      this.setState({
        organizationName: response.body.organization_name,
        judgeTeam: response.body.judge_team,
        organizationUsers: response.body.organization_users.data,
        remainingUsers: [],
        loading: false
      });
    }, (error) => {
      this.setState({
        loading: false,
        error: {
          title: COPY.USER_MANAGEMENT_INITIAL_LOAD_ERROR_TITLE,
          body: error.message
        }
      });
    });
  };

  dropdownOptions = () => {
    return this.state.remainingUsers.map((user) => {
      return { label: this.formatName(user),
        value: user };
    });
  };

  formatName = (user) => {
    return `${user.attributes.full_name} (${user.attributes.css_id})`;
  };

  addUser = ({ value }) => {
    const data = {
      id: value.id
    };

    this.setState({
      addingUser: value
    });

    ApiUtil.post(`/organizations/${this.props.organization}/users`, { data }).then((response) => {

      this.setState({
        organizationUsers: [...this.state.organizationUsers, response.body.users.data[0]],
        remainingUsers: this.state.remainingUsers.filter((user) => user.id !== value.id),
        addingUser: null
      });
    }, (error) => {
      this.setState({
        addingUser: null,
        error: {
          title: COPY.USER_MANAGEMENT_ADD_USER_ERROR_TITLE,
          body: error.message
        }
      });
    });
  }

  removeUser = (user) => () => {
    this.setState({
      removingUser: { ...this.state.removingUser,
        [user.id]: true }
    });

    ApiUtil.delete(`/organizations/${this.props.organization}/users/${user.id}`).then(() => {
      this.setState({
        remainingUsers: [...this.state.remainingUsers, user],
        organizationUsers: this.state.organizationUsers.filter((arrayUser) => arrayUser.id !== user.id),
        removingUser: { ...this.state.removingUser,
          [user.id]: false }
      });
    }, (error) => {
      let errorDetail = error.message;

      if (error.response.text) {
        const errors = JSON.parse(error.response.text).errors;

        if (errors[0] && errors[0].detail) {
          errorDetail = errors[0].detail;
        }
      }

      this.setState({
        removingUser: { ...this.state.removingUser,
          [user.id]: false },
        error: {
          title: COPY.USER_MANAGEMENT_REMOVE_USER_ERROR_TITLE,
          body: errorDetail
        }
      });
    });
  }

  modifyUser = (user, flagName) => {
    this.setState({
      [flagName]: { ...this.state[flagName],
        [user.id]: true }
    });
  }

  modifyUserSuccess = (response, user, flagName) => {
    const updatedUser = response.body.users.data[0];
    // Replace the existing version of the user so it has the updated attributes
    const updatedUserList = this.state.organizationUsers.map((existingUser) => {
      return (existingUser.id === updatedUser.id) ? updatedUser : existingUser;
    });

    this.setState({
      organizationUsers: updatedUserList,
      [flagName]: { ...this.state[flagName],
        [user.id]: false }
    });
  }

  modifyUserError = (title, body, user, flagName) => {
    this.setState({
      [flagName]: { ...this.state[flagName],
        [user.id]: false },
      error: {
        title,
        body
      }
    });
  }

  modifyAdminRights = (user, adminFlag) => () => {
    const flagName = 'changingAdminRights';

    this.modifyUser(user, flagName);

    const payload = { data: { admin: adminFlag } };

    ApiUtil.patch(`/organizations/${this.props.organization}/users/${user.id}`, payload).then((response) => {
      this.modifyUserSuccess(response, user, flagName);
    }, (error) => {
      this.modifyUserError(COPY.USER_MANAGEMENT_ADMIN_RIGHTS_CHANGE_ERROR_TITLE, error.message, user, flagName);
    });
  }

  modifyDecisionDrafting = (user, attorneyFlag) => () => {
    const flagName = 'changingDecisionDrafting';

    this.modifyUser(user, flagName);

    const payload = { data: { attorney: attorneyFlag } };

    ApiUtil.patch(`/organizations/${this.props.organization}/users/${user.id}`, payload).then((response) => {
      this.modifyUserSuccess(response, user, flagName);
    }, (error) => {
      this.modifyUserError(COPY.USER_MANAGEMENT_DECISION_DRAFTING_CHANGE_ERROR_TITLE, error.message, user, flagName);
    });
  }

  asyncLoadUser = (inputValue) => {
    // don't search till we have min length input
    if (inputValue.length < 2) {
      return Promise.reject();
    }

    return ApiUtil.get(`/users?exclude_org=${this.props.organization}&css_id=${inputValue}`).then((response) => {
      const users = response.body.users.data;

      this.setState({
        remainingUsers: users
      });

      return { options: this.dropdownOptions() };
    });
  }

  decisionDraftingButton = (user, attorney) =>
    <span {...buttonPaddingStyle}><Button
      name={attorney ? COPY.USER_MANAGEMENT_DISABLE_DECISION_DRAFTING_BUTTON_TEXT : COPY.USER_MANAGEMENT_ENABLE_DECISION_DRAFTING_BUTTON_TEXT}
      id={attorney ? `Disable-decision-drafting-${user.id}` : `Enable-decision-drafting-${user.id}`}
      classNames={attorney ? ['usa-button-secondary'] : ['usa-button-primary']}
      loading={this.state.changingDecisionDrafting[user.id]}
      onClick={this.modifyDecisionDrafting(user, !attorney)} /></span>

  adminButton = (user, admin) =>
    <span {...buttonPaddingStyle}><Button
      name={admin ? COPY.USER_MANAGEMENT_REMOVE_USER_ADMIN_RIGHTS_BUTTON_TEXT : COPY.USER_MANAGEMENT_GIVE_USER_ADMIN_RIGHTS_BUTTON_TEXT}
      id={admin ? `Remove-admin-rights-${user.id}` : `Add-team-admin-${user.id}`}
      classNames={admin ? ['usa-button-secondary'] : ['usa-button-primary']}
      loading={this.state.changingAdminRights[user.id]}
      onClick={this.modifyAdminRights(user, !admin)} /></span>

  removeUserButton = (user) =>
    <span {...buttonPaddingStyle}><Button
      name={COPY.USER_MANAGEMENT_REMOVE_USER_FROM_ORG_BUTTON_TEXT}
      id={`Remove-user-${user.id}`}
      classNames={['usa-button-secondary']}
      loading={this.state.removingUser[user.id]}
      onClick={this.removeUser(user)} /></span>

  mainContent = () => {
    const judgeTeam = this.state.judgeTeam;
    const listOfUsers = this.state.organizationUsers.map((user, i) => {
      const { judge, attorney, admin } = user.attributes;
      const topStyle = i === 0 ? topUserStyle : {};

      return <React.Fragment>
        <li key={user.id} {...topStyle}>{this.formatName(user)}
          { judgeTeam && judge && <strong> ( {COPY.USER_MANAGEMENT_JUDGE_LABEL} )</strong> }
          { judgeTeam && attorney && <strong> ( {COPY.USER_MANAGEMENT_ATTORNEY_LABEL} )</strong> }
          { judgeTeam && admin && <strong> ( {COPY.USER_MANAGEMENT_ADMIN_LABEL} )</strong> } &nbsp;</li>
        <div {...userStyle}>
          { judgeTeam && !judge && this.decisionDraftingButton(user, attorney) }
          { this.adminButton(user, admin) }
          { this.removeUserButton(user) }
        </div>
      </React.Fragment>;
    });

    return <React.Fragment>
      <h2>{COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_LABEL}</h2>
      <SearchableDropdown
        name={COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_NAME}
        hideLabel
        searchable
        readOnly={Boolean(this.state.addingUser)}
        placeholder={
          this.state.addingUser ?
            `${COPY.USER_MANAGEMENT_ADD_USER_LOADING_MESSAGE} ${this.formatName(this.state.addingUser)}` :
            COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_TEXT
        }
        value={null}
        onChange={this.addUser}
        async={this.asyncLoadUser} />
      <br />
      <div>
        { judgeTeam &&
            <div>
              <h2>{COPY.USER_MANAGEMENT_EDIT_USER_IN_ORG_LABEL}</h2>
              <ul>
                <li><strong>{COPY.USER_MANAGEMENT_DECISION_DRAFTING_HEADING}</strong>{COPY.USER_MANAGEMENT_DECISION_DRAFTING_DESCRIPTION}</li>
                <li><strong>{COPY.USER_MANAGEMENT_ADMIN_RIGHTS_HEADING}</strong>{COPY.USER_MANAGEMENT_ADMIN_RIGHTS_DESCRIPTION}</li>
                <li><strong>{COPY.USER_MANAGEMENT_REMOVE_USER_HEADING}</strong>{COPY.USER_MANAGEMENT_REMOVE_USER_DESCRIPTION}</li>
              </ul>
            </div>
        }
        <ul>{listOfUsers}</ul>
      </div>
    </React.Fragment>;
  }

  render = () => <LoadingDataDisplay
    createLoadPromise={this.loadingPromise}
    loadingComponentProps={{
      spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
      message: COPY.USER_MANAGEMENT_INITIAL_LOAD_LOADING_MESSAGE
    }}
    failStatusMessageProps={{
      title: COPY.USER_MANAGEMENT_INITIAL_LOAD_ERROR_TITLE
    }}>
    <AppSegment filledBackground>
      { this.state.error && <Alert title={this.state.error.title} type="error">
        {this.state.error.body}
      </Alert>}
      <div>
        <h1>{sprintf(COPY.USER_MANAGEMENT_PAGE_TITLE, this.state.organizationName)}</h1>
        {this.mainContent()}
      </div>
    </AppSegment>
  </LoadingDataDisplay>;
}

OrganizationUsers.propTypes = {
  organization: PropTypes.string
};
