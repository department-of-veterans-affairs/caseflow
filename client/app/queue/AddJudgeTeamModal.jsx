import * as React from 'react';
import ApiUtil from '../util/ApiUtil';
import editModalBase from './components/EditModalBase';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { LOGO_COLORS } from '../constants/AppConstants';
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
      return this.setState({ nonJudges: resp.body.non_judges.data })
    });
  }

  selectJudge = (value) => this.setState({ selectedJudge: value });

  formatName = (user) => `${user.attributes.full_name} (${user.attributes.css_id})`;

  dropdownOptions = () => {
    return this.state.nonJudges.map((user) => { return { label: this.formatName(user), value: user } });
  }

  submit = () => {
    return ApiUtil.post(`/team_management/judge_team/${this.state.selectedJudge.value.id}`).then((resp) => {
      // TODO: Do something with this response.
      });
  }

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

export default withRouter(editModalBase(AddJudgeTaskModal, { title: "Create JudgeTeam", pathAfterSubmit: '/team_management' }));
