import React from 'react';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ApiUtil from '../util/ApiUtil';
import Alert from '../components/Alert';
import Button from '../components/Button';

import COPY from '../../COPY';
import USER_STATUSES from '../../constants/USER_STATUSES';
import TextField from '../components/TextField';

const buttonPaddingStyle = css({ margin: '0 1rem' });

const textFieldStyling = css({
  padding: '0 1.5rem',
  width: '50%'
});

const searchButtonStyling = css({
  marginBottom: '1rem',
  textAlign: 'right',
  width: '100%'
});

export default class UserManagement extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      loading: false,
      error: null,
      changingActiveStatus: {},
      selectedUser: null
    };
  }

  formatName = (user) => `${user.full_name} (${user.css_id})`;

  toggleUserStatus = (user, status) => () => {
    this.setState({
      changingActiveStatus: {
        ...this.state.changingActiveStatus,
        [user.id]: true
      }
    });

    const payload = { data: { status } };

    ApiUtil.patch(`/users/${user.id}`, payload).then((response) => {
      const updatedUser = response.body.user;

      const successAlert = status === USER_STATUSES.inactive ?
        {
          title: sprintf(COPY.USER_MANAGEMENT_INACTIVE_SUCCESS_TITLE, this.formatName(user)),
          body: sprintf(COPY.USER_MANAGEMENT_INACTIVE_SUCCESS_BODY, this.formatName(user))
        } : {
          title: sprintf(COPY.USER_MANAGEMENT_ACTIVE_SUCCESS_TITLE, this.formatName(user)),
          body: sprintf(COPY.USER_MANAGEMENT_ACTIVE_SUCCESS_BODY, this.formatName(user))
        };

      this.setState({
        selectedUser: updatedUser,
        changingActiveStatus: {
          ...this.state.changingActiveStatus,
          [user.id]: false
        },
        error: null,
        success: successAlert
      });
    }, (error) => {
      this.setState({
        changingActiveStatus: {
          ...this.state.changingActiveStatus,
          [user.id]: false
        },
        success: null,
        error: {
          title: COPY.USER_MANAGEMENT_STATUS_CHANGE_ERROR_TITLE,
          body: error.message
        }
      });
    });
  }

  search = () => {
    ApiUtil.get(`/user?css_id=${this.state.css_id}`).then((response) => {
      const user = response.body.user;

      this.setState({ selectedUser: user });
    }, (error) => {
      this.setState({
        error: {
          title: COPY.USER_MANAGEMENT_USER_SEARCH_ERROR_TITLE,
          body: error.message
        }
      });
    });
  }

  setCssId = (value) => this.setState({
    css_id: value,
    selectedUser: null,
    error: null,
    success: null
  });

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
      <div>
        <div {...textFieldStyling}>
          <TextField
            name="CSS ID"
            value={this.state.css_id}
            onChange={this.setCssId}
          />
        </div>
        <div {...searchButtonStyling}>
          <Button name="Search" onClick={this.search} />
        </div>
      </div>
      <div>{this.state.selectedUser && this.selectedUserDisplay(this.state.selectedUser)}</div>
    </React.Fragment>;
  }

  render = () => <AppSegment filledBackground>
    { this.state.error && <Alert title={this.state.error.title} type="error">{this.state.error.body}</Alert> }
    { this.state.success && <Alert title={this.state.success.title} type="success">{this.state.success.body}</Alert> }
    <div>
      <h1>{COPY.USER_MANAGEMENT_STATUS_PAGE_TITLE}</h1>
      <p>{COPY.USER_MANAGEMENT_PAGE_DESCRIPTION}</p>
      {this.mainContent()}
    </div>
  </AppSegment>
}
