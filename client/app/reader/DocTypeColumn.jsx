import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { selectCurrentPdfLocally } from '../reader/Documents/DocumentsActions';

import ViewableItemLink from '../components/ViewableItemLink';
import Highlight from '../components/Highlight';

class DocTypeColumn extends React.PureComponent {
  onClick = () => this.props.selectCurrentPdfLocally(this.props.doc.id);

  render = () => {
    const { doc } = this.props;

    // We add a click handler to mark a document as read even if it's opened in a new tab.
    // This will get fired in the current tab, as the link is followed in a new tab. We
    // also need to add a mouseUp event since middle clicking doesn't trigger an onClick.
    // This will not work if someone right clicks and opens in a new tab.
    return <div>
      <ViewableItemLink
        boldCondition={!doc.opened_by_current_user}
        onOpen={this.onClick}
        linkProps={{
          to: `${this.props.documentPathBase}/${doc.id}`,
          'aria-label': doc.type + (doc.opened_by_current_user ? ' opened' : ' unopened')
        }}>
        <Highlight>
          {doc.type}
        </Highlight>
      </ViewableItemLink>
      {doc.description && <p className="document-list-doc-description">
        {doc.description}
      </p>}
    </div>;
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
