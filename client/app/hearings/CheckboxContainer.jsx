import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/dockets';
import Checkbox from '../components/Checkbox';

export class CheckboxContainer extends React.Component {

  updateCheckbox = (value) => {
    this.props.updateCheckbox(this.props.action, this.props.id, value);
  }

  render() {
    return <Checkbox
      label="Transcript Requested"
      name={this.props.id}
      onChange={this.updateCheckbox}
      value={this.props[this.props.id] || this.props.defaultValue || false}
      tabIndex={this.props.tabIndex}
    ></Checkbox>;
  }
}

const mapStateToProps = (state, ownProps) => ({
  [ownProps.id]: state[ownProps.id]
});

const mapDispatchToProps = (dispatch) => ({
  updateCheckbox: (actionName, prop, value) => {
    let action = Actions[actionName];

    dispatch(action(prop, value));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CheckboxContainer);

CheckboxContainer.propTypes = {
  id: PropTypes.string.isRequired
};
