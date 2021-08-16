import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import StringUtil from '../util/StringUtil';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import TabWindow from '../components/TabWindow';
import TextField from '../components/TextField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import Alert from '../components/Alert';
import _ from 'lodash';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default class TestUsers extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      currentUser: props.currentUser,
      userSelect: props.currentUser.id,
      isSwitching: false,
      isLoggingIn: false,
      reseedingError: null,
      isReseeding: false
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
  featureToggleOnChange = (value, deletedValue) => {
    ApiUtil.post('/test/toggle_feature', { data: {
      enable: value,
      disable: deletedValue
    }
    }).then(() => {
      window.location.reload();
    });
  }

  handleLogInAsUser = () => {
    this.setState({ isLoggingIn: true });
    ApiUtil.post(`/test/log_in_as_user?id=${this.state.userId}`).
      then(() => {
        window.location = '/help';
      }).
      catch((err) => {
        this.setState(
          { isLoggingIn: false,
            userId: ''
          });
        console.warn(err);
      });
  }

  reseed = () => {
    this.setState({ isReseeding: true });
    ApiUtil.post('/test/reseed').then(() => {
      this.setState({
        reseedingError: null,
        isReseeding: false
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        reseedingError: err,
        isReseeding: false
      });
    });
  }

  render() {
    const userOptions = this.props.testUsersList.map((user) => ({
      value: user.id,
      label: `${user.css_id} at ${user.station_id} - ${user.full_name}`
    }));

    const featureOptions = this.props.featuresList.map((feature) => ({
      value: feature,
      label: feature,
      tagId: feature
    }));

    const tabs = this.props.appSelectList.map((app) => {
      let tab = {};

      tab.disable = false;
      tab.label = `${app.name}`;

      tab.page = <div>
        <ul>
          {Object.keys(app.links).map((name) => {
            let readableName = StringUtil.snakeCaseToCapitalized(name);

            return <li key={name} aria-labelledby={name}>
              <a href={app.links[name]} id={name} role="link" aria-label={readableName}>{readableName}</a>
            </li>;
          })}
        </ul>
        { app.name === 'Dispatch' && <div>
          <p>
                For Dispatch, we process different types of grants.
                You can select which type you want to preload.</p>
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

    return <BrowserRouter>
      <div>
        <NavigationBar
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          appName="Test Users"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <AppSegment filledBackground>
            <h1>Welcome to the Caseflow admin page.</h1>
            { this.props.userSession &&
              <div>
                <p>Your session</p>
                <pre>{JSON.stringify(this.props.userSession, null, 2)}</pre>
                <p>Server timezone</p>
                <pre>{JSON.stringify(this.props.timezone, null, 2)}</pre>
              </div>
            }
            { this.props.dependenciesFaked &&
              <div>
                <p>
                  Here you can test out different user stories by selecting
                  a Test User and accessing different parts of the application.</p>
                <section className="usa-form-large">
                  <h3>User Selector:</h3>
                  <SearchableDropdown
                    name="Test user dropdown"
                    hideLabel
                    options={userOptions} searchable
                    onChange={this.handleUserSelect}
                    value={this.state.userSelect} />
                  <Button
                    onClick={this.handleUserSwitch}
                    name="Switch user"
                    loading={this.state.isSwitching}
                    loadingText="Switching users" />
                </section>
                <br />
                <h3>App Selector:</h3>
                <TabWindow
                  tabs={tabs}
                  tabPanelTabIndex={-1}
                />
                <p>
                Not all applications are available to every user. Additionally,
                some users have access to different parts of the same application.
                  <br />This button reseeds the database with default values.</p>
                {this.state.reseedingError &&
                  <Alert
                    message={this.state.reseedingError.toString()}
                    type="error"
                  />
                }
                <Button
                  onClick={this.reseed}
                  name="Reseed the DB"
                  loading={this.state.isReseeding}
                  loadingText="Reseeding the DB" />
                <br /> <br />
                <h3>Global Feature Toggles Enabled:</h3>
                <SearchableDropdown
                  name="feature_toggles"
                  label="Remove or add new feature toggles"
                  multi
                  creatable
                  options={featureOptions}
                  placeholder=""
                  value={featureOptions}
                  selfManageValueState
                  onChange={this.featureToggleOnChange}
                  creatableOptions={{ promptTextCreator: (tagName) => `Enable feature toggle "${_.trim(tagName)}"` }}
                />
                <div>
                  <h3>Local Veteran Records</h3>
                  <p>
                    Local veteran records are now available on a <a href="/test/data">separate page</a>.
                    Note that this page may take a while to load.
                  </p>
                </div>
              </div> }
            { this.props.isGlobalAdmin &&
            <div>
              <strong>Log in as user:</strong>
              <TextField
                label="User ID:"
                name="userId"
                value={this.state.userId}
                onChange={this.userIdOnChange} />
              <Button
                onClick={this.handleLogInAsUser}
                name="Log in as user"
                loading={this.state.isLoggingIn}
                loadingText="Logging in" />
            </div>}
          </AppSegment>
        </AppFrame>
      </div>
    </BrowserRouter>;
  }

}

TestUsers.propTypes = {
  currentUser: PropTypes.object.isRequired,
  isGlobalAdmin: PropTypes.bool,
  testUsersList: PropTypes.array.isRequired,
  featuresList: PropTypes.array.isRequired,
  appSelectList: PropTypes.array.isRequired,
  epTypes: PropTypes.array.isRequired,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  userSession: PropTypes.object.isRequired,
  timezone: PropTypes.object,
  dependenciesFaked: PropTypes.bool
};
