import React from 'react';

// components
import Button from '../../components/Button';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideLoadingButton extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: {
        default: false,
        cert: false,
        dispatch: false,
        efolder: false,
        feedback: false
      }
    };
  }

  toggle = (event) => {
    let state = this.state;
    let attr = event.target.getAttribute("id").split("-")[1];

    state.loading[attr] = !state.loading[attr];
    this.setState(state);
  }

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Loading Buttons"
        id="loading_buttons"
        link="StyleGuideLoadingButton.jsx"
      />
      <p>
        Our button components are able to react to a <em>loading</em> property which,
        when <em>true</em>, causes the button to show <strong>Loading... </strong>
        beside a spinning icon.
      </p>
      <p>
        <Button
          id="btn-default"
          name={"See It In Action"}
          onClick={this.toggle}
          loading={this.state.loading.default}
        />
        <Button
          id="reset-default"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
        />
      </p>
      <p>
        <Button
          app="dispatch"
          id="btn-dispatch"
          name={"Dispatch: See It In Action"}
          onClick={this.toggle}
          loading={this.state.loading.dispatch}
        />
        <Button
          id="reset-dispatch"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
        />
      </p>
      <p>
        <Button
          app="cert"
          id="btn-cert"
          name={"Cert: See It In Action"}
          onClick={this.toggle}
          loading={this.state.loading.cert}
        />
        <Button
          id="reset-cert"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
        />
      </p>
      <p>
        <Button
          app="efolder"
          id="btn-efolder"
          name={"Efolder: See It In Action"}
          onClick={this.toggle}
          loading={this.state.loading.efolder}
        />
        <Button
          id="reset-efolder"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
        />
      </p>
      <p>
        <Button
          app="feedback"
          id="btn-feedback"
          name={"Feedback: See It In Action"}
          onClick={this.toggle}
          loading={this.state.loading.feedback}
        />
        <Button
          id="reset-feedback"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
        />
      </p>
    </div>;
  }
}
