import React from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants';

class CaseSelect extends React.PureComponent {
  render() {
    return <div>Hello World</div>;
  }
}

// const mapStateToProps = (state, ownProps) => {
//   const doc = state.documents[ownProps.docId];

//   return {
//     docId: doc.id,
//     expanded: doc.listComments,
//     annotationsCount: _.size(makeGetAnnotationsByDocumentId(state)(ownProps.docId))
//   };
// };

// const mapDispatchToProps = (dispatch) => ({
//   handleToggleCommentOpened(docId) {
//     dispatch({
//       type: Constants.TOGGLE_COMMENT_LIST,
//       payload: {
//         docId
//       }
//     });
//   }
// });

export default connect(
  null,
  null
)(CaseSelect);
