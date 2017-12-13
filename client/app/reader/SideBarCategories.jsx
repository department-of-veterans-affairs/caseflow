import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import * as Constants from '../reader/constants';
import { categoryFieldNameOfCategoryName } from './utils';
import { handleCategoryToggle } from '../reader/Documents/DocumentsActions';

class SideBarCategories extends PureComponent {
  render() {
    const {
      doc,
      documents
    } = this.props;

    const categoryToggleStates = _.mapValues(
      Constants.documentCategories,
      (val, key) =>
        documents[doc.id][categoryFieldNameOfCategoryName(key)]
    );

    return <div className="cf-category-sidebar">
      {this.props.error.category.visible && <CannotSaveAlert />}
      <DocCategoryPicker
        allowReadOnly
        handleCategoryToggle={_.partial(this.props.handleCategoryToggle, doc.id)}
        categoryToggleStates={categoryToggleStates} />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    handleCategoryToggle
  }, dispatch)
});

const mapStateToProps = (state) => {
  return {
    error: state.readerReducer.ui.pdfSidebar.error,
    documents: state.documents
  };
};

export default connect(
  mapStateToProps, mapDispatchToProps
)(SideBarCategories);
