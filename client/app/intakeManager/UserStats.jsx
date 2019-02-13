import React from 'react';
import Table from '../components/Table';
import SearchBar from '../components/SearchBar';
import ApiUtil from '../util/ApiUtil';

export default class UserStats extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      selectedUser: props.selectedUser,
      userStats: [],
      isSwitching: false,
      error: false
    };
  }

  transformUserStats = (stats) => {
    return stats;
  }

  handleUserSelect = (value) => this.setState({ selectedUser: value });
  handleUserSwitch = () => {
    const userId = this.state.selectedUser;

    if (!userId) {
      this.setState({
        error: false,
        userStats: [],
        isSwitching: false
      });

      return;
    }

    this.setState({ isSwitching: true });
    ApiUtil.get(`/intake/manager/users/${userId}`).then((response) => {
      this.setState({
        error: false,
        userStats: this.transformUserStats(JSON.parse(response.text)),
        isSwitching: false
      });
    }).
      catch((err) => {
        console.warn(err);
        this.setState({
          isSwitching: false,
          userStats: [],
          error: `Not found: ${userId}`
        });
      });
  };

  clearSearch = () => {
    this.setState({ userSelect: null });
  }

  render = () => {
    const columns = [
      {
        header: 'Date',
        valueFunction: (row) => {
          return row.date;
        }
      },
      {
        header: 'Higher-Level Reviews',
        valueFunction: (row) => {
          return row.higher_level_review;
        }
      },
      {
        header: 'Appeals',
        valueFunction: (row) => {
          return row.appeal;
        }
      },
      {
        header: 'Supplemental Claims',
        valueFunction: (row) => {
          return row.supplemental_claim;
        }
      }
    ];

    return <div className="cf-app-segment cf-app-segment--alt cf-manager-intakes">
      <div id="cf-user-stats">
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
          <div className="cf-error">{this.state.error}</div>
          <Table columns={columns} rowObjects={this.state.userStats} slowReRendersAreOk />
        </div>
      </div>
    </div>;
  }
}
