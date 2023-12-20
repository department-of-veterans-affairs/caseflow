import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import DocCategoryPicker from '../reader/DocCategoryPicker';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import * as Constants from '../reader/constants';
import { categoryFieldNameOfCategoryName } from './utils';
import { handleCategoryToggle } from '../reader/Documents/DocumentsActions';
import PropTypes from 'prop-types';

class SideBarCategories extends PureComponent {
  componentDidMount() {
    window.addEventListener('keydown', this.keyHandler);
  }

  componentWillUnmount() {
    window.removeEventListener('keydown', this.keyHandler);
  }

  keyHandler = (event) => {
    if (event.altKey) {
      if (event.shiftKey) {
        const doc = this.props.doc;

        if (event.code === 'KeyM') {
          this.props.handleCategoryToggle(doc.id, 'medical', !doc.category_medical);
        } else if (event.code === 'KeyP') {
          this.props.handleCategoryToggle(doc.id, 'procedural', !doc.category_procedural);
        } else if (event.code === 'KeyO') {
          this.props.handleCategoryToggle(doc.id, 'other', !doc.category_other);
        }
      }
    }
  }

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

SideBarCategories.propTypes = {
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
)(SideBarCategories);
