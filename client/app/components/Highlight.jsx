import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import Highlighter from 'react-highlight-words';
import _ from 'lodash';

class Highlight extends PureComponent {
  render() {
    const { searchQuery, textToHighlight } = this.props;

    return <Highlighter
      searchWords={_.union([searchQuery], searchQuery.split(' '))}
      textToHighlight={textToHighlight}
    />;
  }
}

Highlight.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  textToHighlight: PropTypes.string.isRequired
};

export default Highlight;
