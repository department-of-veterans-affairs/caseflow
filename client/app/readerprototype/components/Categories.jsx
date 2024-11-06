import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../../reader/DocCategoryPicker';
import CannotSaveAlert from '../../reader/CannotSaveAlert';
import * as Constants from '../../reader/constants';
import { categoryFieldNameOfCategoryName } from '../../reader/utils';
import { handleCategoryToggle } from '../../reader/Documents/DocumentsActions';
import PropTypes from 'prop-types';

const Categories = ({ doc, documents, error }) => {

  const categoryToggleStates = () => {
    _.mapValues(
      Constants.documentCategories,
      (val, key) =>
        documents[doc.id][categoryFieldNameOfCategoryName(key)]
    );
  };

  return (
    <div className="cf-category-sidebar">
      {error.category.visible && <CannotSaveAlert />}
      <DocCategoryPicker
        allowReadOnly
        handleCategoryToggle={_.partial(handleCategoryToggle, doc.id)}
        categoryToggleStates={categoryToggleStates} />
    </div>
  );
};

Categories.propTypes = {
  doc: PropTypes.object,
  documents: PropTypes.object,
  id: PropTypes.number,
  category_medical: PropTypes.bool,
  category_procedural: PropTypes.bool,
  category_other: PropTypes.bool,
  handleCategoryToggle: PropTypes.func,
  error: PropTypes.object,
  category: PropTypes.object,
  visible: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    handleCategoryToggle
  }, dispatch)
});

const mapStateToProps = (state) => {
  return {
    error: state.pdfViewer.pdfSideBarError,
    documents: state.documents
  };
};

export default connect(
  mapStateToProps, mapDispatchToProps
)(Categories);
