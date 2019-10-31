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
import COPY from '../../COPY.json';
import LoadingDataDisplay from '../components/LoadingDataDisplay';

const buttonPaddingStyle = css({ margin: '0 1rem' });

export default class OrganizationUsers extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      organizationName: null,
      organizationUsers: [],
      remainingUsers: [],
      loading: true,
      error: null,
      addingUser: null,
      removingUser: {},
      changingAdminRights: {}
    };
  }

  loadingPromise = () => {
    return ApiUtil.get(`/organizations/${this.props.organization}/users`).then((response) => {
      this.setState({
        organizationName: response.body.organization_name,
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

    ApiUtil.post(`/organizations/${this.props.organization}/users`, { data }).then(() => {
      this.setState({
        organizationUsers: [...this.state.organizationUsers, value],
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
      this.setState({
        removingUser: { ...this.state.removingUser,
          [user.id]: false },
        error: {
          title: COPY.USER_MANAGEMENT_REMOVE_USER_ERROR_TITLE,
          body: error.message
        }
      });
    });
  }

  modifyAdminRights = (user, adminFlag) => () => {
    this.setState({
      changingAdminRights: { ...this.state.changingAdminRights,
        [user.id]: true }
    });

    const payload = { data: { admin: adminFlag } };

    ApiUtil.patch(`/organizations/${this.props.organization}/users/${user.id}`, payload).then((response) => {
      const updatedUser = response.body.users.data[0];

      // Replace the existing version of the user so it has the correct admin priveleges.
      const updatedUserList = this.state.organizationUsers.map((existingUser) => {
        return (existingUser.id === updatedUser.id) ? updatedUser : existingUser;
      });

      this.setState({
        organizationUsers: updatedUserList,
        changingAdminRights: { ...this.state.changingAdminRights,
          [user.id]: false }
      });
    }, (error) => {
      this.setState({
        changingAdminRights: { ...this.state.changingAdminRights,
          [user.id]: false },
        error: {
          title: COPY.USER_MANAGEMENT_ADMIN_RIGHTS_CHANGE_ERROR_TITLE,
          body: error.message
        }
      });
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

  mainContent = () => {
    const listOfUsers = this.state.organizationUsers.map((user) => {
      return <li key={user.id}>{this.formatName(user)} &nbsp;
        <span {...buttonPaddingStyle}>
          { !user.attributes.admin && <Button
            name={COPY.USER_MANAGEMENT_GIVE_USER_ADMIN_RIGHTS_BUTTON_TEXT}
            id={`Make-user-admin-${user.id}`}
            classNames={['usa-button-primary']}
            loading={this.state.changingAdminRights[user.id]}
            onClick={this.modifyAdminRights(user, true)} /> }
          { user.attributes.admin && <Button
            name={COPY.USER_MANAGEMENT_REMOVE_USER_ADMIN_RIGHTS_BUTTON_TEXT}
            id={`Remove-admin-rights-${user.id}`}
            classNames={['usa-button-secondary']}
            loading={this.state.changingAdminRights[user.id]}
            onClick={this.modifyAdminRights(user, false)} /> }
        </span>
        <Button
          name={COPY.USER_MANAGEMENT_REMOVE_USER_FROM_ORG_BUTTON_TEXT}
          id={`Remove-user-${user.id}`}
          classNames={['usa-button-secondary']}
          loading={this.state.removingUser[user.id]}
          onClick={this.removeUser(user)} />
      </li>;
    });

    return <React.Fragment>
      <ul>{listOfUsers}</ul>
      <h1>{COPY.USER_MANAGEMENT_ADD_USER_TO_ORG_DROPDOWN_LABEL}</h1>
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
