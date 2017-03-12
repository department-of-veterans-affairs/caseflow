import React from 'react';

// components
import ProgressBar from '../../components/ProgressBar';
import ProgressBarSection from '../../components/ProgressBarSection';
import EstablishClaimProgressBar from '../EstablishClaimPage/EstablishClaimProgressBar';
import Button from '../../components/Button';

export default class StyleGuideProgressBar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      section1: false,
      section2: false,
      section3: false
    };

    // activateSection = (section) => () => {
    //   this.setState({
    //     section1: true,
    //     section2: true,
    //     section3: true
    //   })
    };
  };

  render() {
    let {
      section1,
      section2,
      section3
    } = this.props;

    return <div>
      <h2 id="tabs">Progress Bar</h2>
      <p>
        Something.
      </p>
      <ProgressBar
        sections = {
        [
          {
            activated: this.props.section1,
            title: '1. Review Decision'
          },
          {
            activated: this.props.section2,
            title: '2. Route Claim'
          },
          {
            activated: this.props.section3,
            title: '3. Confirmation'
          }
        ]
      }
      />
      <EstablishClaimProgressBar
        isConfirmation={this.state.section1}
        isReviewDecision={this.state.section2}
        isRouteClaim={this.state.section3}
      />
    <div className="cf-sg-progress-bar">
      <Button
        name="Toggle Section 1"
        classNames={["cf-sg-progress-bar-section"]}
      />
      <Button
        name="Toggle Section 2"
        classNames={["cf-sg-progress-bar-section"]}
      />
      <Button
        name="Toggle Section 3"
        classNames={["cf-sg-progress-bar-section"]}
      />
    </div>
  </div>;
};
}
