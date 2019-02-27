import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import editModalBase from './components/EditModalBase';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { LOGO_COLORS } from '../constants/AppConstants';
import { onReceiveNewJudgeTeam } from './teamManagement/actions';
import {
  requestSave,
  showErrorMessage
} from './uiReducer/uiActions';
import { withRouter } from 'react-router-dom';

class AddJudgeTaskModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      nonJudges: [],
      selectedJudge: null
    };
  }

  loadingPromise = () => {
    return ApiUtil.get('/users?role=non_judges').then((resp) => {
      return this.setState({ nonJudges: resp.body.non_judges.data });
    });
  }

  selectJudge = (value) => this.setState({ selectedJudge: value });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () =>
    this.state.nonJudges.map((user) => ({ label: this.formatName(user),
      value: user }));

  submit = () => this.props.requestSave(`/team_management/judge_team/${this.state.selectedJudge.value.id}`).
    then((resp) => this.props.onReceiveNewJudgeTeam(resp.body)).
    catch((err) => this.props.showErrorMessage({ title: 'Error',
      detail: err }));

  render = () => {
    return <LoadingDataDisplay
      createLoadPromise={this.loadingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading users...'
      }}
      failStatusMessageProps={{ title: 'Unable to load users' }}>
      <SearchableDropdown
        name="Select judge"
        hideLabel
        searchable
        placeholder="Select judge"
        value={this.state.selectedJudge}
        onChange={this.selectJudge}
        options={this.dropdownOptions()} />
    </LoadingDataDisplay>;
  };
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewJudgeTeam,
  requestSave,
  showErrorMessage
}, dispatch);

const modalOptions = { title: 'Create JudgeTeam',
  pathAfterSubmit: '/team_management' };

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(editModalBase(AddJudgeTaskModal, modalOptions)));

