import React from 'react';
import { connect } from 'react-redux';

class SwitchOnForm extends React.PureComponent {
    render = () => {
      const { formType, formComponentMapping, componentForNoFormSelected } = this.props;

      if (!formType) {
        return componentForNoFormSelected;
      }

      const child = formComponentMapping[formType];

      // eslint-disable-next-line no-undefined
      if (child === undefined) {
        throw new Error(`SwitchOnForm does not have a mapping for current form selection: '${formType}'`);
      }

      return child;
    }
}

SwitchOnForm.defaultProps = {
  componentForNoFormSelected: null
};

const ConnectedSwitchOnForm = connect(
  ({ formType }) => ({ formType })
)(SwitchOnForm);

export default ConnectedSwitchOnForm;

