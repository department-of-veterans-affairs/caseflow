import React, { useState, useMemo } from 'react';
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
import { trim, escapeRegExp } from 'lodash';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default function TestUsers(props) {

  const [userSelect, setUserSelect] = useState(props.currentUser.id);
  const [userId, setUserId] = useState('');
  const [isSwitching, setIsSwitching] = useState(false);
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [reseedingError, setReseedingError] = useState(null);
  const [isReseeding, setIsReseeding] = useState(false);
  const [inputValue, setInputValue] = useState('');

  const handleEpSeed = (type) => ApiUtil.post(`/test/set_end_products?type=${type}`).
    catch((err) => {
      console.warn(err);
    });

  const handleInputChange = (value) => setInputValue(value);
  const handleUserSelect = ({ value }) => {
    setUserSelect(value);
  };

  const handleUserSwitch = () => {
    setIsSwitching(true);
    ApiUtil.post(`/test/set_user/${userSelect}`).then(() => {
      window.location.reload();
    }).
      catch((err) => {
        console.warn(err);
      });
  };

  const userIdOnChange = (value) => setUserId(value);
  const featureToggleOnChange = (value, deletedValue) => {
    ApiUtil.post('/test/toggle_feature', { data: {
      enable: value,
      disable: deletedValue
    }
    }).then(() => {
      window.location.reload();
    });
  };

  const handleLogInAsUser = () => {
    setIsLoggingIn(true);
    ApiUtil.post(`/test/log_in_as_user?id=${userId}`).
      then(() => {
        window.location = '/help';
      }).
      catch((err) => {
        setIsLoggingIn(false);
        setUserId('');
        console.warn(err);
      });
  };

  const reseed = () => {
    setIsReseeding(true);
    ApiUtil.post('/test/reseed').then(() => {
      setReseedingError(null);
      setIsReseeding(false);
    }, (err) => {
      console.warn(err);
      setReseedingError(err);
      setIsReseeding(false);
    });
  };

  const filteredUserOptions = useMemo(() => {
    const userOptions = props.testUsersList.map((user) => ({
      value: user.id,
      label: `${user.css_id} at ${user.station_id} - ${user.full_name}`
    }));

    if (!inputValue) {
      return userOptions;
    }

    const matchByStart = [];
    const matchByInclusion = [];

    const regByInclusion = new RegExp(escapeRegExp(inputValue), 'i');
    const regByStart = new RegExp(`^${escapeRegExp(inputValue)}`, 'i');

    for (const option of userOptions) {
      if (regByInclusion.test(option.label)) {
        if (regByStart.test(option.label)) {
          matchByStart.push(option);
        } else {
          matchByInclusion.push(option);
        }
      }
    }

    return [...matchByStart, ...matchByInclusion];
  }, [inputValue]);

  const slicedUserOptions = useMemo(
    () => filteredUserOptions.slice(0, 500),
    [filteredUserOptions]
  );

  const featureOptions = props.featuresList.map((feature) => ({
    value: feature,
    label: feature,
    tagId: feature
  }));

  const tabs = props.appSelectList.map((app) => {
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
          { props.epTypes.map((type) => {
            const label = `Seed ${type} grants`;

            return <li key={type}>
              <Button
                onClick={() => handleEpSeed(type)}
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
        userDisplayName={props.userDisplayName}
        dropdownUrls={props.dropdownUrls}
        appName="Test Users"
        logoProps={{
          accentColor: COLORS.GREY_DARK,
          overlapColor: COLORS.GREY_DARK
        }} />
      <AppFrame>
        <AppSegment filledBackground>
          <h1>Welcome to the Caseflow admin page.</h1>
          { props.userSession &&
              <div>
                <p>Your session</p>
                <pre>{JSON.stringify(props.userSession, null, 2)}</pre>
                <p>Server timezone</p>
                <pre>{JSON.stringify(props.timezone, null, 2)}</pre>
              </div>
          }
          { props.dependenciesFaked &&
              <div>
                <p>
                  Here you can test out different user stories by selecting
                  a Test User and accessing different parts of the application.</p>
                <section className="usa-form-large">
                  <h3>User Selector:</h3>
                  <SearchableDropdown
                    name="Test user dropdown"
                    hideLabel
                    onInputChange={handleInputChange}
                    options={slicedUserOptions} searchable
                    onChange={handleUserSelect}
                    // Disable native filter
                    filterOption={() => true}
                    value={userSelect} />
                  <Button
                    onClick={handleUserSwitch}
                    name="Switch user"
                    loading={isSwitching}
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
                {reseedingError &&
                  <Alert
                    message={reseedingError.toString()}
                    type="error"
                  />
                }
                <Button
                  onClick={reseed}
                  name="Reseed the DB"
                  loading={isReseeding}
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
                  onChange={featureToggleOnChange}
                  creatableOptions={{ promptTextCreator: (tagName) => `Enable feature toggle "${trim(tagName)}"` }}
                />
                <div>
                  <h3>Local Veteran Records</h3>
                  <p>
                    Local veteran records are now available on a <a href="/test/data">separate page</a>.
                    Note that this page may take a while to load.
                  </p>
                </div>
              </div> }
          { props.isGlobalAdmin &&
            <div>
              <strong>Log in as user:</strong>
              <TextField
                label="User ID:"
                name="userId"
                value={userId}
                onChange={userIdOnChange} />
              <Button
                onClick={handleLogInAsUser}
                name="Log in as user"
                loading={isLoggingIn}
                loadingText="Logging in" />
            </div>}
        </AppSegment>
      </AppFrame>
    </div>
  </BrowserRouter>;
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
  userSession: PropTypes.object,
  timezone: PropTypes.object,
  dependenciesFaked: PropTypes.bool
};
