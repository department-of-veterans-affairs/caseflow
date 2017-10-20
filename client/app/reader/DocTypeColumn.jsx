import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { selectCurrentPdfLocally } from './actions';

import { bindActionCreators } from 'redux';
import Link from '../components/Link';
import Highlight from '../components/Highlight';

class DocTypeColumn extends React.PureComponent {
  boldUnreadContent = (content, doc) => {
    if (!doc.opened_by_current_user) {
      return <strong>{content}</strong>;
    }

    return content;
  };

  onClick = (id) => () => {
    // Annoyingly if we make this call in the thread, it won't follow the link. Instead
    // we use setTimeout to force it to run at a later point.
    setTimeout(() => this.props.selectCurrentPdfLocally(id), 0);
  }

  render = () => {
    const { doc } = this.props;

    // We add a click handler to mark a document as read even if it's opened in a new tab.
    // This will get fired in the current tab, as the link is followed in a new tab. We
    // also need to add a mouseUp event since middle clicking doesn't trigger an onClick.
    // This will not work if someone right clicks and opens in a new tab.
    return this.boldUnreadContent(
      <Link
        onMouseUp={this.onClick(doc.id)}
        onClick={this.onClick(doc.id)}
        to={`${this.props.documentPathBase}/${doc.id}`}
        aria-label={doc.type + (doc.opened_by_current_user ? ' opened' : ' unopened')}>
        <Highlight>
          {doc.type}
        </Highlight>
      </Link>, doc);
  }
}

const mapDocTypeDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    selectCurrentPdfLocally
  }, dispatch)
});

DocTypeColumn.propTypes = {
  doc: PropTypes.object,
  documentPathBase: PropTypes.string
};

export default connect(
  null, mapDocTypeDispatchToProps
)(DocTypeColumn);
