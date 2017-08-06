import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import Checkbox from '../components/Checkbox';

export class CheckboxContainer extends React.Component {

  updateCheckbox = (value) => {
    this.props.updateCheckbox(this.props.action, this.props.id, value);
  }

  render() {
    return <Checkbox
      label={this.props.label}
      name={this.props.id}
      onChange={this.updateCheckbox}
      value={this.props[this.props.id] || this.props.defaultValue || false}
    />;
  }
}

const mapDispatchToProps = (dispatch) => ({
  updateCheckbox: (actionName, prop, value) => {
    dispatch(Actions[actionName](prop, value));
  }
});

export default connect(
  null,
  mapDispatchToProps
)(CheckboxContainer);

CheckboxContainer.propTypes = {
  id: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired
};
