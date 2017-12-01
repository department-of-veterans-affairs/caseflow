import React, { PureComponent } from 'react';
<<<<<<< HEAD
=======
import { bindActionCreators } from 'redux';
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import * as Constants from '../reader/constants';
import { categoryFieldNameOfCategoryName } from './utils';
<<<<<<< HEAD
import ApiUtil from '../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from './analytics';
import { toggleDocumentCategoryFail } from '../reader/actions';
=======
import { handleCategoryToggle } from '../reader/DocumentList/DocumentListActions';
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b

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
<<<<<<< HEAD
      {this.props.showErrorMessage.category && <CannotSaveAlert />}
=======
      {this.props.error.category.visible && <CannotSaveAlert />}
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
      <DocCategoryPicker
        allowReadOnly
        handleCategoryToggle={_.partial(this.props.handleCategoryToggle, doc.id)}
        categoryToggleStates={categoryToggleStates} />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
<<<<<<< HEAD
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
=======
  ...bindActionCreators({
    handleCategoryToggle
  }, dispatch)
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
});

const mapStateToProps = (state) => {
  return {
<<<<<<< HEAD
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
=======
    error: state.readerReducer.ui.pdfSidebar.error
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
  };
};

export default connect(
  mapStateToProps, mapDispatchToProps
)(SideBarCategories);
