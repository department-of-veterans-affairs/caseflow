import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { clearAllFilters } from './actions';
import Button from '../components/Button';

class HeaderFilterMessage extends React.PureComponent {
  render() {
    const props = this.props;

    // returns the number of truthy values in an object
    const getTruthyCount = (obj) => _(obj).
      values().
      compact().
      size();

    const categoryCount = getTruthyCount(props.docFilterCriteria.category);
    const tagCount = getTruthyCount(props.docFilterCriteria.tag);

    let filteredCategories = _.compact([
      categoryCount && `Categories (${categoryCount})`,
      tagCount && `Issue tags (${tagCount})`,
      props.viewingDocumentsOrComments === 'comments' && 'Comments'
    ]).join(', ');

    if (!filteredCategories.length) {
      filteredCategories = 'None';
    }

    return <p className="document-list-filter-message">Filtering by: {filteredCategories}.<Button
      id="clear-filters"
      name="clear-filters"
      classNames={['cf-btn-link']}
      onClick={props.clearAllFilters}
      disabled={!(categoryCount || tagCount)}>
      Clear all filters.</Button></p>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearAllFilters
}, dispatch);

HeaderFilterMessage.propTypes = {
  docFilterCriteria: PropTypes.object,
  clearAllFilters: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  viewingDocumentsOrComments: state.readerReducer.viewingDocumentsOrComments
});

export default connect(mapStateToProps, mapDispatchToProps)(HeaderFilterMessage);
