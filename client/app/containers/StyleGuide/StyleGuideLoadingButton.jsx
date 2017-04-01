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
    let buttonName = "See it in action";

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
        <span className="loading-button-example">Default:</span>
        <Button
          id="btn-default"
          name={buttonName}
          onClick={this.toggle}
          loading={this.state.loading.default}
        />
        <Button
          id="reset-default"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
          disabled={!this.state.loading.default}
        />
      </p>
      <p>
        <span className="loading-button-example">Dispatch:</span>
        <Button
          app="dispatch"
          id="btn-dispatch"
          name={buttonName}
          onClick={this.toggle}
          loading={this.state.loading.dispatch}
        />
        <Button
          id="reset-dispatch"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
          disabled={!this.state.loading.dispatch}
        />
      </p>
      <p>
        <span className="loading-button-example">Certification:</span>
        <Button
          app="cert"
          id="btn-cert"
          name={buttonName}
          onClick={this.toggle}
          loading={this.state.loading.cert}
        />
        <Button
          id="reset-cert"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
          disabled={!this.state.loading.cert}
        />
      </p>
      <p>
        <span className="loading-button-example">eFolder:</span>
        <Button
          app="efolder"
          id="btn-efolder"
          name={buttonName}
          onClick={this.toggle}
          loading={this.state.loading.efolder}
        />
        <Button
          id="reset-efolder"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
          disabled={!this.state.loading.efolder}
        />
      </p>
      <p>
        <span className="loading-button-example">Feedback:</span>
        <Button
          app="feedback"
          id="btn-feedback"
          name={buttonName}
          onClick={this.toggle}
          loading={this.state.loading.feedback}
        />
        <Button
          id="reset-feedback"
          name={"Reset"}
          onClick={this.toggle}
          classNames={["cf-btn-link"]}
          disabled={!this.state.loading.feedback}
        />
      </p>
    </div>;
  }
}
