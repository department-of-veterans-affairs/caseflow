import React from 'react';
import Button from '../../components/Button';
import { fullWidth } from '../constants';
import _ from 'lodash';

const DecisionViewFooter = ({ buttons }) => <div {...fullWidth}>
  {buttons.map((button, idx) => <Button
    id={button.id}
    key={idx}
    onClick={button.callback || _.noop}
    willNeverBeLoading
    disabled={button.disabled}
    classNames={button.classNames}>
    {button.displayText}
  </Button>)}
</div>;

export default DecisionViewFooter;
