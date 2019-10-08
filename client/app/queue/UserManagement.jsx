import React from 'react';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ApiUtil from '../util/ApiUtil';
import Alert from '../components/Alert';
import Button from '../components/Button';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';

import { LOGO_COLORS } from '../constants/AppConstants';
import COPY from '../../COPY.json';
import USER_STATUSES from '../../constants/USER_STATUSES.json';

const buttonPaddingStyle = css({ margin: '0 1rem' });

export default class UserManagement extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      loading: true,
      error: null,
      changingActiveStatus: {},
      selectedUser: null
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/users').then((response) => {
      this.setState({
        users: response.body.users,
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
    return this.state.users.map((user) => {
      return { label: this.formatName(user),
        value: user };
    });
  };

  formatName = (user) => {
    return `${user.full_name} (${user.css_id})`;
  };

  toggleUserStatus = (user, status) => () => {
    this.setState({
      changingActiveStatus: { ...this.state.changingActiveStatus,
        [user.id]: true }
    });

    const payload = { data: { status } };

    ApiUtil.patch(`/users/${user.id}`, payload).then((response) => {
      const updatedUser = response.body.user;

      // Replace the existing version of the user so it has the correct status.
      const updatedUserList = this.state.users.map((existingUser) => {
        return (existingUser.id === updatedUser.id) ? updatedUser : existingUser;
      });

      this.setState({
        users: updatedUserList,
        selectedUser: updatedUser,
        changingActiveStatus: { ...this.state.changingActiveStatus,
          [user.id]: false },
        error: null,
        success: {
          title: sprintf(
            status === USER_STATUSES.inactive ?
              COPY.USER_MANAGEMENT_INACTIVE_SUCCESS_TITLE :
              COPY.USER_MANAGEMENT_ACTIVE_SUCCESS_TITLE,
            this.formatName(user)),
          body: sprintf(
            status === USER_STATUSES.inactive ?
              COPY.USER_MANAGEMENT_INACTIVE_SUCCESS_BODY :
              COPY.USER_MANAGEMENT_ACTIVE_SUCCESS_BODY,
            this.formatName(user))
        }
      });
    }, (error) => {
      this.setState({
        changingActiveStatus: { ...this.state.changingActiveStatus,
          [user.id]: false },
        success: null,
        error: {
          title: COPY.USER_MANAGEMENT_STATUS_CHANGE_ERROR_TITLE,
          body: error.message
        }
      });
    });
  }

  selectUser = (user) => {
    this.setState({ selectedUser: user.value });
  }

  selectedUserDisplay = (user) => {
    return <span>{this.formatName(user)} &nbsp;
      <span {...buttonPaddingStyle}>
        { user.status === USER_STATUSES.inactive ?
          <Button
            name={COPY.USER_MANAGEMENT_GIVE_USER_ACTIVE_STATUS_BUTTON_TEXT}
            classNames={['usa-button-primary']}
            loading={this.state.changingActiveStatus[user.id]}
            onClick={this.toggleUserStatus(user, USER_STATUSES.active)} /> :
          <Button
            name={COPY.USER_MANAGEMENT_GIVE_USER_INACTIVE_STATUS_BUTTON_TEXT}
            classNames={['usa-button-secondary']}
            loading={this.state.changingActiveStatus[user.id]}
            onClick={this.toggleUserStatus(user, USER_STATUSES.inactive)} /> }
      </span>
    </span>;
  }

  mainContent = () => {
    return <React.Fragment>
      <h2>{COPY.USER_MANAGEMENT_SELECT_USER_DROPDOWN_LABEL}</h2>
      <SearchableDropdown
        searchable
        placeholder={COPY.USER_MANAGEMENT_SELECT_USER_DROPDOWN_TEXT}
        name={COPY.USER_MANAGEMENT_SELECT_USER_DROPDOWN_TEXT}
        hideLabel
        value={null}
        onChange={this.selectUser}
        options={this.dropdownOptions()} />
      <span>{this.state.selectedUser && this.selectedUserDisplay(this.state.selectedUser)}</span>
    </React.Fragment>;
  }

  render = () => <LoadingDataDisplay
    createLoadPromise={this.loadingPromise}
    loadingComponentProps={{
      spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
      message: COPY.USER_MANAGEMENT_INITIAL_LOADING_MESSAGE
    }}
    failStatusMessageProps={{
      title: COPY.USER_MANAGEMENT_INITIAL_ERROR_TITLE
    }}>
    <AppSegment filledBackground>
      { this.state.error && <Alert title={this.state.error.title} type="error">{this.state.error.body}</Alert> }
      { this.state.success && <Alert title={this.state.success.title} type="success">{this.state.success.body}</Alert> }
      <div>
        <h1>{COPY.USER_MANAGEMENT_STATUS_PAGE_TITLE}</h1>
        <p>{COPY.USER_MANAGEMENT_PAGE_DESCRIPTION}</p>
        {this.mainContent()}
      </div>
    </AppSegment>
  </LoadingDataDisplay>;
}
