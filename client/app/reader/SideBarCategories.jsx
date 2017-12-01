import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import * as Constants from '../reader/constants';
import { categoryFieldNameOfCategoryName } from './utils';
import ApiUtil from '../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from './analytics';
import { toggleDocumentCategoryFail } from '../reader/actions';

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
      {this.props.showErrorMessage.category && <CannotSaveAlert />}
      <DocCategoryPicker
        allowReadOnly
        handleCategoryToggle={_.partial(this.props.handleCategoryToggle, doc.id)}
        categoryToggleStates={categoryToggleStates} />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  handleCategoryToggle(docId, categoryName, toggleState) {
    const categoryKey = categoryFieldNameOfCategoryName(categoryName);

    ApiUtil.patch(
      `/document/${docId}`,
      { data: { [categoryKey]: toggleState } },
      ENDPOINT_NAMES.DOCUMENT
    ).catch(() =>
      dispatch(toggleDocumentCategoryFail(docId, categoryKey, !toggleState))
    );

    dispatch({
      type: Constants.TOGGLE_DOCUMENT_CATEGORY,
      payload: {
        categoryKey,
        toggleState,
        docId
      },
      meta: {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: `${toggleState ? 'set' : 'unset'} document category`,
          label: categoryName
        }
      }
    });
  }
});

const mapStateToProps = (state) => {
  return {
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
  };
};

export default connect(
  mapStateToProps, mapDispatchToProps
)(SideBarCategories);
