import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import StatusMessage from '../components/StatusMessage';
import { connect } from 'react-redux';
import { clearSearch } from './actions';
import _ from 'lodash';

export class NoSearchResults extends PureComponent {
  render() {
    return <div className="section--no-search-results">
      <StatusMessage
        title="Search results not found">
        Sorry! We couldn't find anything for "{this.props.searchQuery.trim()}."<br />
        Please search again or <a href="#" onClick={this.props.clearSearch}>go back to the document list.</a>
      </StatusMessage>
    </div>;
  }
}

NoSearchResults.propTypes = {
  clearSearch: PropTypes.func.isRequired,
  searchQuery: PropTypes.string
};

const mapStateToProps = (state) => _.pick(state.ui.docFilterCriteria, 'searchQuery');

const mapDispatchToProps = (dispatch) => ({
  clearSearch() {
    dispatch(clearSearch());
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(NoSearchResults);
