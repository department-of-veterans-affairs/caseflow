import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY.json';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { onReceiveNewPrivateBar } from './teamManagement/actions';
import {
  requestSave,
  showErrorMessage
} from './uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './components/QueueFlowModal';

class AddPrivateBarModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      vsoUsers: [],
      selectedPrivateBarUser: null
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/users?role=vso_staff').then((resp) => {
      return this.setState({ vsoUsers: resp.body.vso_staff.data });
    });
  }

  selectPrivateBarUser = (value) => this.setState({ selectedPrivateBarUser: value });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () =>
    this.state.vsoUsers.map((user) => ({ label: this.formatName(user),
      value: user }));

  submit = () => this.props.requestSave(`/team_management/private_bar/${this.state.selectedPrivateBarUser.value.id}`).
    then((resp) => this.props.onReceiveNewPrivateBar(resp.body)).
    catch((err) => this.props.showErrorMessage({ title: 'Error',
      detail: err }));

  render = () => {
    return <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_PRIVATE_BAR_MODAL_TITLE}
      pathAfterSubmit="/team_management"
      submit={this.submit}
    >
      <LoadingDataDisplay
        createLoadPromise={this.loadingPromise}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          message: COPY.USER_MANAGEMENT_INITIAL_LOAD_LOADING_MESSAGE
        }}
        failStatusMessageProps={{ title: COPY.USER_MANAGEMENT_INITIAL_LOAD_ERROR_TITLE }}>
        <SearchableDropdown
          name={COPY.TEAM_MANAGEMENT_SELECT_PRIVATE_ATTORNEY_LABEL}
          hideLabel
          searchable
          placeholder={COPY.TEAM_MANAGEMENT_SELECT_PRIVATE_ATTORNEY_LABEL}
          value={this.state.selectedPrivateBarUser}
          onChange={this.selectPrivateBarUser}
          options={this.dropdownOptions()} />
      </LoadingDataDisplay>
    </QueueFlowModal>;
  };
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewPrivateBar,
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddPrivateBarModal));

