import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';
import COPY from '../../COPY.json';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import PropTypes from 'prop-types';
import SearchableDropdown from '../components/SearchableDropdown';
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
      results: null
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

  selectUser = (value) => this.setState({ selectedUser: value });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () =>
    this.state.users.map((user) => ({ label: this.formatName(user),
      value: user }));

  search = () => {
    const url = `/users/${this.state.selectedUser.value.id}/represented_organizations`;

    // Clear previous results before every attempt.
    this.setState({ representedOrganizations: null });
    this.clearAlerts();

    return this.props.requestGet(url).
      then((resp) => this.setState({ representedOrganizations: resp.body.represented_organizations })).
      catch((err) => this.props.showErrorMessage({ title: 'Error',
        detail: err.message }));
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

