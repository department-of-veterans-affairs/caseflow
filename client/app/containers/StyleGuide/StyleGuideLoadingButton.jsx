import React from 'react';

// components
import Button from '../../components/Button';

export default class StyleGuideLoadingButton extends React.Component {

  startLoading = () => {
    this.setState({
      loading: true
    });
  }

  reset = () => {
    this.setState({
      loading: false
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
        onClick={this.startLoading}
        loading={this.state && this.state.loading}
      />
      <Button
        name={"Reset"}
        onClick={this.reset}
        classNames={["cf-btn-link"]}
      />
    </div>;
  }
}
