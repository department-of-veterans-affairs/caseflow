import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { fullWidth } from '../constants';
import { noop } from 'lodash';

const DecisionViewFooter = ({ buttons }) => (
  <div {...fullWidth}>
    {buttons.map((button, idx) => (
      <Button key={idx} onClick={button.callback || noop} {...button}>
        {button.displayText}
      </Button>
    ))}
  </div>
);

DecisionViewFooter.propTypes = {
  buttons: PropTypes.arrayOf(
    PropTypes.shape({
      classNames: PropTypes.arrayOf(PropTypes.string),
      callback: PropTypes.func,
      name: PropTypes.string,
      displayText: PropTypes.string,
      willNeverBeLoading: PropTypes.bool,
    })
  ),
};

export default DecisionViewFooter;
