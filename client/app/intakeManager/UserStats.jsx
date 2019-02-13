import React from 'react';
import Button from '../components/Button';
import { formatDate } from '../util/DateUtil';
import Table from '../components/Table';
import SearchBar from '../components/SearchBar';
import ApiUtil from '../util/ApiUtil';

export default class UserStats extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      selectedUser: props.selectedUser,
      userStats: {},
      isSwitching: false
    };
  }

  handleUserSelect = (value) => this.setState({ selectedUser: value });
  handleUserSwitch = () => {
    const userId = this.state.selectedUser;
    this.setState({ isSwitching: true });
    ApiUtil.get(`/intake/manager/users/${userId}`).then((response) => {
      const stats = JSON.parse(response.text);
      this.setState({ userStats: stats });
    }).
    catch((err) => {
      console.warn(err);
    });
  };

  clearSearch = () => {
    this.setState({ userSelect: null })
  }

  render = () => {
    return <div className="cf-app-segment cf-app-segment--alt cf-manager-intakes">
      <div className="cf-manage-intakes-header">
        <div>
          <h1>Intake Stats per User</h1>
          <section className="usa-form-large">
            <SearchBar
              size="small"
              title="Enter the User ID"
              onSubmit={this.handleUserSwitch}
              onChange={this.handleUserSelect}
              onClearSearch={this.clearSearch}
              value={this.state.userSelect}
              loading={this.state.isSwitching}
              submitUsingEnterKey
            />
          </section>
        </div>
      </div>
    </div>;
  }
}
