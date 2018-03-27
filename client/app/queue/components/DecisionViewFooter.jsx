import React from 'react';
import { connect } from 'react-redux';
import Button from '../../components/Button';
import { fullWidth } from '../constants';
import _ from 'lodash';

class DecisionViewFooter extends React.Component {
  render = () => <div {...fullWidth}>
    {this.props.footerButtons.map((button, idx) => <Button
      id={button.id}
      key={idx}
      onClick={button.callback || _.noop}
      willNeverBeLoading
      disabled={button.disabled}
      classNames={button.classNames}>
      {button.displayText}
    </Button>)}
  </div>;
}

const mapStateToProps = (state) => _.pick(state.ui, 'footerButtons');

export default connect(mapStateToProps)(DecisionViewFooter);
