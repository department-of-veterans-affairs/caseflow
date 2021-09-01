import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY.json';
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
import QueueFlowModal from './components/QueueFlowModal';

class AddJudgeTeamModal extends React.Component {
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
    this.state.nonJudges?.map((user) => ({ label: this.formatName(user),
      value: user }));

  submit = () => this.props.requestSave(`/team_management/judge_team/${this.state.selectedJudge.value.id}`).
    then((resp) => this.props.onReceiveNewJudgeTeam(resp.body)).
    catch((err) => this.props.showErrorMessage({ title: 'Error',
      detail: err }));

  render = () => {
    return <QueueFlowModal
      title={COPY.TEAM_MANAGEMENT_ADD_JUDGE_TEAM_MODAL_TITLE}
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
          name={COPY.TEAM_MANAGEMENT_SELECT_JUDGE_LABEL}
          hideLabel
          searchable
          placeholder={COPY.TEAM_MANAGEMENT_SELECT_JUDGE_LABEL}
          value={this.state.selectedJudge}
          onChange={this.selectJudge}
          options={this.dropdownOptions()} />
      </LoadingDataDisplay>
    </QueueFlowModal>;
  };
}

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveNewJudgeTeam,
  requestSave,
  showErrorMessage
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(AddJudgeTeamModal));

