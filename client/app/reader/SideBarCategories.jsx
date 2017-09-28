import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import * as Constants from '../reader/constants';
import { categoryFieldNameOfCategoryName } from './utils';

class SideBarCategories extends PureComponent {
  render() {
    let {
      doc,
      documents,
      showErrorMessage,
      handleCategoryToggle
    } = this.props;

    const categoryToggleStates = _.mapValues(
      Constants.documentCategories,
      (val, key) =>
        documents[doc.id][categoryFieldNameOfCategoryName(key)]
    );

    return <div className="cf-category-sidebar">
      {showErrorMessage.category && <CannotSaveAlert />}
      <DocCategoryPicker
        allowReadOnly={true}
        handleCategoryToggle={handleCategoryToggle}
        categoryToggleStates={categoryToggleStates} />
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
  };
};

export default connect(
  mapStateToProps
)(SideBarCategories);
