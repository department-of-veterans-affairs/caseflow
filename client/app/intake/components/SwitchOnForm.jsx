import React from 'react';
import { connect } from 'react-redux';

class SwitchOnForm extends React.PureComponent {
    render = () => {
      const { formSelection, formComponentMapping, componentForNoFormSelected } = this.props;

      if (!formSelection) {
        return componentForNoFormSelected;
      }

      const child = formComponentMapping[formSelection];

      // eslint-disable-next-line no-undefined
      if (child === undefined) {
        throw new Error(`SwitchOnForm does not have a mapping for current form selection: '${formSelection}'`);
      }

      return child;
    }
}

SwitchOnForm.defaultProps = {
  componentForNoFormSelected: null
};

const ConnectedSwitchOnForm = connect(
  ({ formSelection }) => ({ formSelection })
)(SwitchOnForm);

export default ConnectedSwitchOnForm;

