import React from 'react';
import { connect } from 'react-redux';

import NonCompTabs from '../components/NonCompTabs';
import Button from '../../components/Button';

const textAlignRightStyling = {
  textAlign: 'right'
};

const maxWidth = {
  maxWidth: '100%'
};

class NonCompPageUnconnected extends React.PureComponent {
  render = () => {
    return <div>
      <h1>{this.props.businessLine}</h1>
      <div className="usa-grid-full" style={maxWidth}>
        <div className="usa-width-two-thirds">
          <h2>Reviews needing action</h2>
          <div>Review each issue and select a disposition</div>
        </div>
        <div className="usa-width-one-thirds" style={textAlignRightStyling}>
          <Button onClick={() => {
            window.location.href = '/intake';
          }}
          classNames={['usa-button']}
          >
            + Intake new form
          </Button>
        </div>
      </div>
      <NonCompTabs />
    </div>;
  }
}

const NonCompPage = connect(
  (state) => ({
    businessLine: state.businessLine
  })
)(NonCompPageUnconnected);

export default NonCompPage;
