import React from 'react';

// components
import Button from '../../components/Button';

export default class StyleGuideLoadingButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: false
    };
  }

  onClick = () => {
    this.setState({
      loading: true
    });
  }

  render() {
    return <div>
      <h2 id="loading_button">Loading Button</h2>
      <p>
        Our button components are able to react to a <em>loading</em> property which,
        when <em>true</em>, causes the button to show <strong>Loading... </strong>
        beside a spinning icon.
      </p>
      <Button
        name={"See It In Action"}
        onClick={this.onClick}
        classNames={["usa-button-primary"]}
        loading={this.state.loading}
      />
    </div>;
  }
}
