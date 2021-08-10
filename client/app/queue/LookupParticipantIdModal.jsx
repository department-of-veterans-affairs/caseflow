import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';
import COPY from '../../COPY';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import { css } from 'glamor';
import { LOGO_COLORS } from '../constants/AppConstants';
import QueueFlowModal from './components/QueueFlowModal';
import Alert from '../components/Alert';
import styles from './LookupParticipantIdModal.module.scss';

class LookupParticipantIdModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      selectedUser: null,
      results: null,
      css_id: null,
      station_id: null,
      alert: null,
      error: ''
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/users?role=non_judges').then((resp) => {
      return this.setState({ users: resp.body.non_judges.data });
    });
  };

  setCssId = (value) =>
    this.setState({
      css_id: value,
      selectedUser: null
    });

  setStationId = (value) =>
    this.setState({
      selectedUser: null,
      station_id: value
    });

  selectUser = (value) =>
    this.setState({
      css_id: null,
      selectedUser: value,
      station_id: null
    });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () => this.state.users.map((user) => ({ label: this.formatName(user),
    value: user }));

  search = async () => {
    const { css_id: cssId, station_id: stationId, selectedUser } = this.state;
    const url =
      cssId && stationId ?
        `/user_info/represented_organizations?css_id=${cssId}&station_id=${stationId}` :
        `/users/${selectedUser.value.id}/represented_organizations`;

    // Clear previous results before every attempt.
    this.setState({
      representedOrganizations: null,
      alert: null
    });

    try {
      const res = await ApiUtil.get(url);

      this.setState({
        representedOrganizations: res.body.represented_organizations,
        alert: 'success'
      });
    } catch (response) {
      const error = response?.body?.errors?.[0];

      this.setState({
        alert: 'error',
        error: error?.detail
      });
    }
  };

  representedOrganizationsList = () => {
    const orgs = this.state.representedOrganizations;

    if (!orgs) {
      return null;
    }

    if (!orgs.length) {
      return <p>{COPY.LOOKUP_PARTICIPANT_ID_MODAL_NO_ORGS_MESSAGE}</p>;
    }

    return (
      <ol>
        {orgs.map((org, idx) => (
          <li key={idx}>
            {org.representative_name}, {org.representative_type}. Participant ID: {org.participant_id}
          </li>
        ))}
      </ol>
    );
  };

  render = () => {
    const { alert, error } = this.state;

    return (
      <QueueFlowModal
        title={COPY.LOOKUP_PARTICIPANT_ID_MODAL_TITLE}
        pathAfterSubmit="/team_management"
        button="Close"
        submit={() => Promise.resolve()}
      >
        <LoadingDataDisplay
          createLoadPromise={this.loadingPromise}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
            message: 'Loading users...'
          }}
          failStatusMessageProps={{ title: 'Unable to load users' }}
        >
          <React.Fragment>
            {alert && (
              <div className={styles.alert}>
                {alert === 'success' && <Alert type={alert} title="Lookup Succeeded" />}
                {alert === 'error' && (
                  <Alert type={alert} title="Error">
                    {error ? error : COPY.LOOKUP_PARTICIPANT_ID_MODAL_ERROR_GENERIC}
                  </Alert>
                )}
              </div>
            )}

            <SearchableDropdown
              name={COPY.LOOKUP_PARTICIPANT_ID_SELECT_USER_LABEL}
              hideLabel
              searchable
              placeholder={COPY.LOOKUP_PARTICIPANT_ID_SELECT_USER_LABEL}
              value={this.state.selectedUser}
              onChange={this.selectUser}
              options={this.dropdownOptions()}
            />
            <p {...css({ fontWeight: 'bold',
              textAlign: 'center' })}>OR</p>
            <div className={styles.textfield}>
              <TextField name="CSS ID" value={this.state.css_id} onChange={this.setCssId} />
            </div>
            <div className={styles.textfield}>
              <TextField name="Station ID" value={this.state.station_id} onChange={this.setStationId} />
            </div>
            {this.representedOrganizationsList()}
            <div className={styles.searchBtn}>
              <Button name="Search" onClick={this.search} />
            </div>
          </React.Fragment>
        </LoadingDataDisplay>
      </QueueFlowModal>
    );
  };
}

LookupParticipantIdModal.propTypes = {};

export default LookupParticipantIdModal;
