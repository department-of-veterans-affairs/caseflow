/* eslint-disable no-nested-ternary */
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
import MembershipRequestTable from './MembershipRequestTable';
import SelectConferenceTypeRadioField from './SelectConferenceTypeRadioField';

const userStyle = css({
  margin: '.5rem 0 .5rem',
  padding: '.5rem 0 .5rem',
  listStyle: 'none'
});
const topUserStyle = css({
  borderTop: '.1rem solid gray',
  margin: '.5rem 0 .5rem',
  padding: '1rem 0 .5rem',
  listStyle: 'none'
});
const topUserBorder = css({
  borderBottom: '.1rem solid gray',
});
const buttonStyle = css({
  paddingRight: '1rem',
  display: 'inline-block'
});
const buttonContainerStyle = css({
  borderBottom: '1rem solid gray',
  borderWidth: '1px',
  padding: '.5rem 7rem 2rem 0',
  display: 'flex',
  justifyContent: 'space-between',
  flexWrap: 'wrap'
});
const listStyle = css({
  listStyle: 'none'
});
const radioContainerStyle = css({
  padding: '-5rem 5rem 2rem 2rem',
});

export default class OrganizationUsers extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      organizationName: null,
      judgeTeam: null,
      organizationUsers: [],
      remainingUsers: [],
      membershipRequests: [],
      loading: true,
      error: null,
      success: null,
      addingUser: null,
      changingAdminRights: {},
      removingUser: {},
      isVhaOrg: false
    };
  }

  loadingPromise = () => {
    return ApiUtil.get(`/organizations/${this.props.organization}/users`).then((response) => {
      this.setState({
        organizationName: response.body.organization_name,
        judgeTeam: response.body.judge_team,
        dvcTeam: response.body.dvc_team,
        organizationUsers: response.body.organization_users.data,
        membershipRequests: response.body.membership_requests,
        remainingUsers: [],
        isVhaOrg: response.body.isVhaOrg,
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
        membershipRequests: this.state.membershipRequests.filter((mr) => parseInt(mr.userId, 10) !== parseInt(value.id, 10)),
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

      return this.dropdownOptions();
    });
  }

  adminButton = (user, admin) =>
    <div {...buttonStyle}><Button
      name={admin ? COPY.USER_MANAGEMENT_REMOVE_USER_ADMIN_RIGHTS_BUTTON_TEXT : COPY.USER_MANAGEMENT_GIVE_USER_ADMIN_RIGHTS_BUTTON_TEXT}
      id={admin ? `Remove-admin-rights-${user.id}` : `Add-team-admin-${user.id}`}
      classNames={admin ? ['usa-button-secondary'] : ['usa-button-primary']}
      loading={this.state.changingAdminRights[user.id]}
      onClick={this.modifyAdminRights(user, !admin)} /></div>

  removeUserButton = (user) =>
    <div {...buttonStyle}><Button
      name={COPY.USER_MANAGEMENT_REMOVE_USER_FROM_ORG_BUTTON_TEXT}
      id={`Remove-user-${user.id}`}
      classNames={['usa-button-secondary']}
      loading={this.state.removingUser[user.id]}
      onClick={this.removeUser(user)} /></div>

  mainContent = () => {
    const judgeTeam = this.state.judgeTeam;
    const dvcTeam = this.state.dvcTeam;
    const listOfUsers = this.state.organizationUsers.map((user, i) => {
      const { dvc, admin } = user.attributes;
      const style = i === 0 ? topUserStyle : userStyle;
      const { conferenceSelectionVisibility } = this.props;

      return (
        <React.Fragment key={user.id}>
          <div>
            <ul>
              <li key={user.id} {...style}>
                {this.formatName(user)}
                {judgeTeam && admin && (
                  <strong> ( {COPY.USER_MANAGEMENT_JUDGE_LABEL} )</strong>
                )}
                {dvcTeam && dvc && (
                  <strong> ( {COPY.USER_MANAGEMENT_DVC_LABEL} )</strong>
                )}
                {judgeTeam && !admin && (
                  <strong> ( {COPY.USER_MANAGEMENT_ATTORNEY_LABEL} )</strong>
                )}
                {(judgeTeam || dvcTeam) && admin && (
                  <strong> ( {COPY.USER_MANAGEMENT_ADMIN_LABEL} )</strong>
                )}
              </li>
              {(judgeTeam || dvcTeam) && admin ? (
                <div {...topUserBorder} />
              ) : (
                <div {...buttonContainerStyle}>
                  <div>
                    {judgeTeam || dvcTeam ? '' : this.adminButton(user, admin)}
                    {this.removeUserButton(user)}
                  </div>
                  {this.state.organizationName === 'Hearings Management' &&
                    !conferenceSelectionVisibility && (
                    <div
                      {...radioContainerStyle}
                    >
                      <SelectConferenceTypeRadioField
                        key={`${user.id}-conference-selection`}
                        name={user.id}
                      />
                    </div>
                  )}
                </div>
              )}
            </ul>
          </div>
        </React.Fragment>
      );
    });

    return <React.Fragment>
      <h2>{COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_LABEL}</h2>
      <SearchableDropdown
        name={COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_NAME}
        hideLabel
        searchable
        clearOnSelect
        readOnly={Boolean(this.state.addingUser)}
        placeholder={
          this.state.addingUser ?
            `${COPY.USER_MANAGEMENT_ADD_USER_LOADING_MESSAGE} ${this.formatName(this.state.addingUser)}` :
            COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_TEXT
        }
        noResultsText={COPY.TEAM_MANAGEMENT_DROPDOWN_LABEL}
        value={null}
        onChange={this.addUser}
        async={this.asyncLoadUser} />
      <br />
      <div>
        <div>
          <h2>{COPY.USER_MANAGEMENT_EDIT_USER_IN_ORG_LABEL}</h2>
          <ul {...listStyle}>
            { (judgeTeam || dvcTeam) ? '' : <ul><li><strong>{COPY.USER_MANAGEMENT_ADMIN_RIGHTS_HEADING}</strong>{COPY.USER_MANAGEMENT_ADMIN_RIGHTS_DESCRIPTION}</li></ul> }
            <ul><li><strong>{COPY.USER_MANAGEMENT_REMOVE_USER_HEADING}</strong>{ judgeTeam ?
              COPY.USER_MANAGEMENT_JUDGE_TEAM_REMOVE_USER_DESCRIPTION :
              COPY.USER_MANAGEMENT_REMOVE_USER_DESCRIPTION }</li></ul>
          </ul>
        </div>
        <ul>{listOfUsers}</ul>
      </div>
    </React.Fragment>;
  }

  membershipRequestHandler = (value) => {
    const [requestId, requestAction] = value.split('-');
    const data = { id: requestId, requestAction };

    ApiUtil.patch(`/membership_requests/${requestId}`, { data }).then((response) => {
      const { membershipRequest, updatedUser } = response.body;
      const titleMessage = sprintf(COPY.MEMBERSHIP_REQUEST_ACTION_SUCCESS_TITLE, membershipRequest.status, membershipRequest.userName);
      const bodyMessage = sprintf(COPY.MEMBERSHIP_REQUEST_ACTION_SUCCESS_MESSAGE, membershipRequest.status === 'approved' ? 'granted' : 'denied', membershipRequest.orgName);

      const newState = {
        membershipRequests: this.state.membershipRequests.filter((request) => request.id !== membershipRequest.id),
        success: {
          title: titleMessage,
          body: bodyMessage,
        },
      };

      // Only update the list of organization users on the page if the request was approved
      if (membershipRequest.status === 'approved') {
        newState.organizationUsers = [...this.state.organizationUsers, updatedUser];
        newState.remainingUsers = this.state.remainingUsers.filter((user) => user.id !== updatedUser.id);
      }

      this.setState(newState);

    }, (error) => {
      this.setState({
        error: {
          title: `Failed to take action for the users request to join ${this.state.organizationName}`,
          body: error.message
        }
      });
    });
  };

  render = () => <LoadingDataDisplay
    createLoadPromise={this.loadingPromise}
    loadingComponentProps={{
      spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
      message: COPY.USER_MANAGEMENT_INITIAL_LOAD_LOADING_MESSAGE
    }}
    failStatusMessageProps={{
      title: COPY.USER_MANAGEMENT_INITIAL_LOAD_ERROR_TITLE
    }}>
    { this.state.success && <Alert title={this.state.success.title} type="success">
      {this.state.success.body}
    </Alert>}
    <AppSegment filledBackground>
      { this.state.error && <Alert title={this.state.error.title} type="error">
        {this.state.error.body}
      </Alert>}
      <div>
        <h1>{ this.state.judgeTeam ? sprintf(COPY.USER_MANAGEMENT_JUDGE_TEAM_PAGE_TITLE, this.state.organizationName) :
          this.state.dvcTeam ? sprintf(COPY.USER_MANAGEMENT_DVC_TEAM_PAGE_TITLE, this.state.organizationName) :
            sprintf(COPY.USER_MANAGEMENT_PAGE_TITLE, this.state.organizationName) }</h1>
        {this.state.isVhaOrg && (<>
          <MembershipRequestTable requests={this.state.membershipRequests} membershipRequestActionHandler={this.membershipRequestHandler} />
          <div style={{ paddingBottom: '7rem' }}></div>
        </>
        )}
        {this.mainContent()}
      </div>
    </AppSegment>
  </LoadingDataDisplay>;
}

OrganizationUsers.propTypes = {
  organization: PropTypes.string,
  conferenceSelectionVisibility: PropTypes.bool
};
