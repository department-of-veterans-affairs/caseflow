import React from 'react';
import Button from '../../components/Button';
import { fullWidth } from '../constants';

const DecisionViewFooter = ({ buttons }) => <div {...fullWidth}>
  {buttons.map((button, idx) => <Button
    key={idx}
    onClick={button.callback}
    classNames={button.classNames}>
    {button.displayText}
  </Button>)}
</div>;

export default DecisionViewFooter;
