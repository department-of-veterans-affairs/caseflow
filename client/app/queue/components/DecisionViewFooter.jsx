import React from 'react';
import Button from '../../components/Button';
import { fullWidth } from '../constants';
import _ from 'lodash';

const DecisionViewFooter = ({ buttons }) => <div {...fullWidth}>
  {buttons.map((button, idx) => <Button
    key={idx}
    onClick={button.callback || _.noop}
    {...button}>
    {button.displayText}
  </Button>)}
</div>;

export default DecisionViewFooter;
