import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import StringUtil from '../util/StringUtil';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import TabWindow from '../components/TabWindow';
import TextField from '../components/TextField';

export default class TestUsers extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      currentUser: props.currentUser,
      userSelect: props.currentUser.id,
      isSwitching: false,
      isLoggingIn: false
    };
  }

  handleEpSeed = (type) => ApiUtil.post(`/test/set_end_products?type=${type}`).
    catch((err) => {
      console.warn(err);
    });
  handleUserSelect = ({ value }) => this.setState({ userSelect: value });
  handleUserSwitch = () => {
    this.setState({ isSwitching: true });
    ApiUtil.post(`/test/set_user/${this.state.userSelect}`).then(() => {
      window.location.reload();
    }).
      catch((err) => {
        console.warn(err);
      });
  };

  userIdOnChange = (value) => this.setState({ userId: value });
  stationIdOnChange = (value) => this.setState({ stationId: value });

  handleLogInAsUser = () => {
    this.setState({ isLoggingIn: true });
    ApiUtil.post(`/test/log_in_as_user?id=${this.state.userId}&station_id=${this.state.stationId}`).then(() => {
      window.location.reload();
    }).
      catch((err) => {
        this.setState(
          { isLoggingIn: false,
            userId: '',
            stationId: '' });
        console.warn(err);
      });
  }

  render() {
    const userOptions = this.props.testUsersList.map((user) => ({
      value: user.id,
      label: `${user.css_id} at ${user.station_id}`
    }));
    const tabs = this.props.appSelectList.map((app) => {
      let tab = {};

      tab.disable = false;
      tab.label = `${app.name}`;

      tab.page = <div>
        <ul>
          {Object.keys(app.links).map((name) => {
            return <li key={name}>
              <a href={app.links[name]}>{StringUtil.snakeCaseToCapitalized(name)}</a>
            </li>;
          })}
        </ul>
        { app.name === 'Dispatch' && <div>
          <p>
                For Dispatch we are processing different types of grants,
                here you can select which type you want to preload.</p>
          <ul>
            { this.props.epTypes.map((type) => {
              const label = `Seed ${type} grants`;

              return <li key={type}>
                <Button
                  onClick={() => this.handleEpSeed(type)}
                  name={label} />
              </li>;
            })}
          </ul>
        </div>
        }
      </div>;

      return tab;
    });

    return <div className="cf-app-segment--alt">
      <div>
        <h1>Welcome to Caseflow Demo!</h1>
        <p>
          Here you can test out different user stories by selecting
          a Test User and accessing different parts of the application.</p>
        <p>
          Some of our users come from different stations acorss the country,
          therefore selecting station 405 might lead to an extra Login screen.</p>
        <strong>User Selector:</strong>
        <SearchableDropdown
          name=""
          options={userOptions} searchable={false}
          onChange={this.handleUserSelect}
          value={this.state.userSelect} />
        <Button
          onClick={this.handleUserSwitch}
          name="Switch user"
          loading={this.state.isSwitching}
          loadingText="Switching users" />
        <br /><br />
        { this.props.isGlobalAdmin &&
        <div>
          <strong>Log in as user:</strong>
          <TextField
            label="User ID:"
            name="userId"
            value={this.state.userId}
            onChange={this.userIdOnChange} />
          <TextField
            label="Station ID:"
            name="stationId"
            value={this.state.stationId}
            onChange={this.stationIdOnChange} />
          <Button
            onClick={this.handleLogInAsUser}
            name="Log in as user"
            loading={this.state.isLoggingIn}
            loadingText="Logging in" />
        </div>}
      </div>
      <p>
        Not all applications are available to every user. Additionally,
        some users have access to different parts of the same application.</p>
      <strong>App Selector:</strong>
      <TabWindow
        tabs={tabs} />
    </div>;
  }

}

TestUsers.propTypes = {
  currentUser: PropTypes.object.isRequired,
  isGlobalAdmin: PropTypes.bool,
  testUsersList: PropTypes.array.isRequired,
  appSelectList: PropTypes.array.isRequired,
  epTypes: PropTypes.array.isRequired
};
