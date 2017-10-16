import React from 'react';

// mostly copy pasted this answer from Stack Overflow: http://stackoverflow.com/a/33555276
// This component adds the "sticking" functionality to a given navigation list

export default class StickyNav extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      className: 'cf-sg-nav-not-scrolling',
      reTopped: ''
    };
  }

  componentDidMount = () => {
    window.addEventListener('scroll', this.handleScroll);
  }

  componentWillUnmount = () => {
    window.removeEventListener('scroll', this.handleScroll);
  }

  handleScroll = () => {
    // Nav bar will attach to top of page if the user scrolls down by 150px
    if (window.scrollY > 150) {
      this.setState({
        className: 'cf-sg-nav-scrolling',
        topClass: 're-topped'
      });
    } else if (window.scrollY < 150) {
      this.setState({
        className: 'cf-sg-nav-not-scrolling',
        topClass: ''
      });
    }
  }

  // TODO(marian): add toggle for nav bar to float right for nice dazzler

  render() {
    return (
      <div className={`cf-sg-nav ${this.state.topClass}`}>
        <div className={this.state.className}>
          <ul className="usa-sidenav-list">
            { this.props.children }
          </ul>
        </div>
      </div>
    );
  }
}
