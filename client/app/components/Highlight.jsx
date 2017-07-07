import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Highlighter from 'react-highlight-words';
import _ from 'lodash';

class Highlight extends PureComponent {
  render() {
    const { searchQuery } = this.props;

    return <div aria-label="search result">
      <Highlighter
        searchWords={_.union([searchQuery], searchQuery.split(' '))}
        textToHighlight={this.props.children}
      />
    </div>;
  }
}

Highlight.propTypes = {
  searchQuery: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  searchQuery: state.ui.docFilterCriteria.searchQuery
});

export default connect(
  mapStateToProps
)(Highlight);
