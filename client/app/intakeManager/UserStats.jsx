/* eslint-disable react/prop-types */
import React from 'react';
import PropTypes from 'prop-types';
import Table from '../components/Table';
import SearchBar from '../components/SearchBar';
import ApiUtil from '../util/ApiUtil';

export default class UserStats extends React.PureComponent {

  constructor(props) {
    super(props);
    this.state = {
      selectedUser: props.selectedUser,
      userStats: [],
      userStatsFetched: false,
      isSwitching: false,
      error: false
    };
  }

  handleUserSelect = (value) => this.setState({ selectedUser: value });
  handleUserSwitch = () => {
    const userId = this.state.selectedUser;

    if (!userId) {
      this.setState({
        error: false,
        userStats: [],
        userStatsFetched: false,
        isSwitching: false
      });

      return;
    }

    this.setState({ isSwitching: true });
    ApiUtil.get(`/intake/manager/users/${userId}`).then((response) => {
      this.setState({
        error: false,
        userStats: response.body,
        userStatsFetched: true,
        isSwitching: false
      });
    }).
      catch((err) => {
        console.warn(err);
        this.setState({
          isSwitching: false,
          userStats: [],
          userStatsFetched: false,
          error: `Not found: ${userId}`
        });
      });
  };

  componentDidMount = () => {
    if (this.state.selectedUser) {
      this.handleUserSwitch();
    }
  };

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

    let tbl = '';

    if (this.state.userStats.length > 0) {
      tbl = <Table columns={columns} rowObjects={this.state.userStats} slowReRendersAreOk />;
    } else if (this.state.userStatsFetched) {
      tbl = <div>No stats available.</div>;
    }

    let preselectedUser = this.props.selectedUser;

    // empty string can break things on initial value.
    if (!preselectedUser || preselectedUser === '') {
      preselectedUser = null;
    }

    return <div className="cf-app-segment cf-app-segment--alt cf-manager-intakes">
      <div id="cf-user-stats">
        <div>
          <h1>Intake Stats per User</h1>
          <section className="usa-form-large">
            <SearchBar
              size="small"
              title="Enter the User ID"
              value={preselectedUser}
              onSubmit={this.handleUserSwitch}
              onChange={this.handleUserSelect}
              loading={this.state.isSwitching}
              submitUsingEnterKey
            />
          </section>
          <div className="cf-error">{this.state.error}</div>
          { tbl }
        </div>
      </div>
    </div>;
  }
}

UserStats.propTypes = {
  selectedUser: PropTypes.string
};
