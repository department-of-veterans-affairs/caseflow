import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { onReceiveNewDvcTeam } from './teamManagement/actions';
import {
  requestSave,
  showErrorMessage
} from './uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

class AddDvcTeamModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      usersWithoutDvcTeam: [],
      selectedDvc: null
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/users?role=non_dvcs').then((resp) => {
      return this.setState({ usersWithoutDvcTeam: resp.body.non_dvcs.data });
    });
  }

  selectDvc = (value) => this.setState({ selectedDvc: value });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () =>
    this.state.usersWithoutDvcTeam.map((user) => ({ label: this.formatName(user),
      value: user }));

  submit = () => this.props.requestSave(`/team_management/dvc_team/${this.state.selectedDvc.value.id}`).
    then((resp) => this.props.onReceiveNewDvcTeam(resp.body)).
    catch((err) => this.props.showErrorMessage({ title: 'Error',
      detail: err }));

  render = () => {
    return <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_DVC_TEAM_MODAL_TITLE}
      pathAfterSubmit="/team_management"
      submit={this.submit}
    >
      <LoadingDataDisplay
        createLoadPromise={this.loadingPromise}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          message: 'Loading users...'
        }}
        failStatusMessageProps={{ title: 'Unable to load users' }}>
        <SearchableDropdown
          name={COPY.TEAM_MANAGEMENT_SELECT_DVC_LABEL}
          hideLabel
          searchable
          placeholder={COPY.TEAM_MANAGEMENT_SELECT_DVC_LABEL}
          value={this.state.selectedDvc}
          onChange={this.selectDvc}
          options={this.dropdownOptions()} />
      </LoadingDataDisplay>
    </QueueFlowModal>;
  };
}

AddDvcTeamModal.propTypes = {
  onReceiveNewDvcTeam: PropTypes.func,
  requestSave: PropTypes.func,
  showErrorMessage: PropTypes.func
};

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewDvcTeam,
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddDvcTeamModal));
