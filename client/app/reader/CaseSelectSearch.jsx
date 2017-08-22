import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { fetchAppealUsingVeteranId,
  clearReceivedAppeals, onReceiveAppealDetails, setCaseSelectSearch,
  clearCaseSelectSearch, caseSelectAppeal, clearSelectedAppeal
} from './actions';

import SearchBar from '../components/SearchBar';

class CaseSelectSearch extends React.PureComponent {

  constructor() {
    super();
    this.state = {
      selectedAppealVacolsId: null
    };
  }

  componentDidUpdate = () => {

    // when an appeal is selected using claim search,
    // this method redirects to the claim folder page
    // and also does a bit of store clean up.
    if (this.props.caseSelect.selectedAppeal.vacols_id) {
      this.props.history.push(`/${this.props.caseSelect.selectedAppeal.vacols_id}/documents`);
      this.props.clearCaseSelectSearch();
      this.props.clearReceivedAppeals();
      this.props.clearSelectedAppeal();
    }
  };

  searchOnChange = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealUsingVeteranId(text);
    }
  }

  render() {
    return <div className="section-search">
      <SearchBar
        id="searchBar"
        size="small"
        onChange={this.props.setCaseSelectSearch}
        value={this.props.caseSelectCriteria.searchQuery}
        onClearSearch={this.props.clearCaseSelectSearch}
        onSubmit={this.searchOnChange}
        submitUsingEnterKey
      />
    </div>;
  }
}


const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchAppealUsingVeteranId,
  clearReceivedAppeals,
  onReceiveAppealDetails,
  setCaseSelectSearch,
  clearCaseSelectSearch,
  caseSelectAppeal,
  clearSelectedAppeal
}, dispatch);

const mapStateToProps = (state) => ({
  ..._.pick(state, 'assignments'),
  ..._.pick(state.ui, 'caseSelect'),
  ..._.pick(state.ui, 'caseSelectCriteria')
});


export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelectSearch);
