import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import LoadingLabel from './LoadingLabel';

import SearchableDropdown from '../SearchableDropdown';

class DocumentTypeCorrespondenceDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getCoordinators, 0);
  }

  getCoordinators = () => {
    const { correspondence: { options, isFetching } } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData('correspondence');

    ApiUtil.get('/queue/correspondence/getTypo').then((resp) => {
      const documents = resp.body.allDocuments.map((doc) => ({
        label: doc.name,
        value: doc.id
      }));

      this.props.onReceiveDropdownData('correspondence', documents);
    });
  }

  getSelectedOption = () => {
    const { value, correspondence: { options } } = this.props;

    return _.find(options, (opt) => opt.label === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const {
      optional, name, label, onChange, readOnly, placeholder,
      correspondence: { isFetching }
    } = this.props;

    return (
      <SearchableDropdown
        optional={optional}
        name={name}
        label={isFetching ? <LoadingLabel text="Loading new document type..." /> : label}
        strongLabel = {false}
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={this.props.correspondence.options}
        // errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

DocumentTypeCorrespondenceDropdown.propTypes = {
  optional: PropTypes.bool,
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func,
  onFetchDropdownData: PropTypes.func,
  onReceiveDropdownData: PropTypes.func.isRequired,
  correspondence: PropTypes.shape({
    options: PropTypes.arrayOf(PropTypes.object),
    isFetching: PropTypes.bool
  }),
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

const mapStateToProps = (state) => ({
  correspondence: state.components.dropdowns.correspondence ? {
    options: state.components.dropdowns.correspondence.options,
    isFetching: state.components.dropdowns.correspondence.isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocumentTypeCorrespondenceDropdown);
