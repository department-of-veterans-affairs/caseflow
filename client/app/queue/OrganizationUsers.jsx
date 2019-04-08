import React from 'react';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ApiUtil from '../util/ApiUtil';
import Alert from '../components/Alert';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';

import { LOGO_COLORS } from '../constants/AppConstants';

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
      const resp = JSON.parse(response.text);

      this.setState({
        organizationName: resp.organization_name,
        organizationUsers: resp.organization_users.data,
        remainingUsers: resp.remaining_users.data,
        loading: false
      });
    }, (error) => {
      this.setState({
        loading: false,
        error: {
          title: 'Failed to load users',
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
          title: 'Failed to add user',
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
          title: 'Failed to remove user',
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
      const resp = JSON.parse(response.text);
      const updatedUser = resp.users.data[0];

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
          title: 'Failed to modify user admin rights',
          body: error.message
        }
      });
    });
  }

  mainContent = () => {
    const listOfUsers = this.state.organizationUsers.map((user) => {
      return <li key={user.id}>{this.formatName(user)} &nbsp;
        <span {...buttonPaddingStyle}>
          { !user.attributes.is_admin && <Button
            name="Make user admin"
            id={`Make-user-admin-${user.id}`}
            classNames={['usa-button-primary']}
            loading={this.state.changingAdminRights[user.id]}
            onClick={this.modifyAdminRights(user, true)} /> }
          { user.attributes.is_admin && <Button
            name="Remove admin rights"
            id={`Remove-admin=rights-${user.id}`}
            classNames={['usa-button-secondary']}
            loading={this.state.changingAdminRights[user.id]}
            onClick={this.modifyAdminRights(user, false)} /> }
        </span>
        <Button
          name="Remove user"
          id={`Remove-user-${user.id}`}
          classNames={['usa-button-secondary']}
          loading={this.state.removingUser[user.id]}
          onClick={this.removeUser(user)} />
      </li>;
    });

    return <React.Fragment>
      <ul>{listOfUsers}</ul>
      <h1>Add a user to the team:</h1>
      <SearchableDropdown
        name="Add user"
        hideLabel
        searchable
        readOnly={Boolean(this.state.addingUser)}
        placeholder={
          this.state.addingUser ? `Adding user ${this.formatName(this.state.addingUser)}` : 'Select user to add'
        }
        value={null}
        onChange={this.addUser}
        options={this.dropdownOptions()} />
    </React.Fragment>;
  }

  render = () => {

    return <LoadingDataDisplay
      createLoadPromise={this.loadingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading user...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load users'
      }}>
      <AppSegment filledBackground>
        { this.state.error && <Alert title={this.state.error.title} type="error">
          {this.state.error.body}
        </Alert>}
        <div>
          <h1>{this.state.organizationName} team</h1>
          {this.mainContent()}
        </div>
      </AppSegment>
    </LoadingDataDisplay>;
  };
}
