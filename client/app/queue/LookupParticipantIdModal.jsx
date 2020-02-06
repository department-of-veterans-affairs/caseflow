import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';
import COPY from '../../COPY';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import PropTypes from 'prop-types';
import SearchableDropdown from '../components/SearchableDropdown';
import TextField from '../components/TextField';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { LOGO_COLORS } from '../constants/AppConstants';
import {
  hideErrorMessage,
  hideSuccessMessage,
  requestGet,
  showErrorMessage
} from './uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

const textFieldStyling = css({
  float: 'left',
  padding: '0 1.5rem',
  width: '50%'
});

const searchButtonStyling = css({
  marginTop: '1rem',
  textAlign: 'right',
  width: '100%'
});

class LookupParticipantIdModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      users: [],
      selectedUser: null,
      results: null,
      css_id: null,
      station_id: null
    };
  }

  componentWillUnmount = () => this.clearAlerts();

  clearAlerts = () => {
    this.props.hideErrorMessage();
    this.props.hideSuccessMessage();
  }

  loadingPromise = () => {
    return ApiUtil.get('/users?role=non_judges').then((resp) => {
      return this.setState({ users: resp.body.non_judges.data });
    });
  }

  setCssId = (value) => this.setState({
    css_id: value,
    selectedUser: null
  });

  setStationId = (value) => this.setState({
    selectedUser: null,
    station_id: value
  });

  selectUser = (value) => this.setState({
    css_id: null,
    selectedUser: value,
    station_id: null
  });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () =>
    this.state.users.map((user) => ({ label: this.formatName(user),
      value: user }));

  search = () => {
    let url = '';

    if (this.state.css_id && this.state.station_id) {
      url = `/user_info/represented_organizations?css_id=${this.state.css_id}&station_id=${this.state.station_id}`;
    } else {
      url = `/users/${this.state.selectedUser.value.id}/represented_organizations`;
    }

    // Clear previous results before every attempt.
    this.setState({ representedOrganizations: null });
    this.clearAlerts();

    return this.props.requestGet(url).
      then((resp) => this.setState({ representedOrganizations: resp.body.represented_organizations })).
      catch(
        // Errors caught and displayed in requestGet().
      );
  }

  representedOrganizationsList = () => {
    const orgs = this.state.representedOrganizations;

    if (!orgs) {
      return null;
    }

    if (!orgs.length) {
      return <p>{COPY.LOOKUP_PARTICIPANT_ID_MODAL_NO_ORGS_MESSAGE}</p>;
    }

    return <ol>
      { orgs.map((org, idx) =>
        <li key={idx}>{org.representative_name}, {org.representative_type}. Participant ID: {org.participant_id}</li>
      ) }
    </ol>;
  };

  render = () => {
    return <QueueFlowModal
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
        failStatusMessageProps={{ title: 'Unable to load users' }}>
        <React.Fragment>
          <SearchableDropdown
            name={COPY.LOOKUP_PARTICIPANT_ID_SELECT_USER_LABEL}
            hideLabel
            searchable
            placeholder={COPY.LOOKUP_PARTICIPANT_ID_SELECT_USER_LABEL}
            value={this.state.selectedUser}
            onChange={this.selectUser}
            options={this.dropdownOptions()} />
          <p {...css({ fontWeight: 'bold',
            textAlign: 'center' })}>OR</p>
          <div {...textFieldStyling}>
            <TextField
              name="CSS ID"
              value={this.state.css_id}
              onChange={this.setCssId}
            />
          </div>
          <div {...textFieldStyling}>
            <TextField
              name="Station ID"
              value={this.state.station_id}
              onChange={this.setStationId}
            />
          </div>
          { this.representedOrganizationsList() }
          <div {...searchButtonStyling}>
            <Button name="Search" onClick={this.search} />
          </div>
        </React.Fragment>
      </LoadingDataDisplay>
    </QueueFlowModal>;
  };
}

LookupParticipantIdModal.propTypes = {
  hideErrorMessage: PropTypes.func,
  hideSuccessMessage: PropTypes.func,
  requestGet: PropTypes.func,
  showErrorMessage: PropTypes.func
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideErrorMessage,
  hideSuccessMessage,
  requestGet,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(LookupParticipantIdModal));

