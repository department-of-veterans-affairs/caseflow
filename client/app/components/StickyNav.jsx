import React from 'react';

// mostly copy pasted this answer from Stack Overflow: http://stackoverflow.com/a/33555276
// This component adds the "sticking" functionality to a given navigation list

export default class StickyNav extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
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
    // Nav bar will attach to top of page if the user scrolls down by 120px
    if (window.scrollY > 120) {
      this.setState({
        topClass: 're-topped'
      });
    } else if (window.scrollY < 120) {
      this.setState({
        topClass: ''
      });
    }
  }

  // TODO(marian): add toggle for nav bar to float right for nice dazzler

  render() {
    return (
      <div className={`cf-sg-nav ${this.state.topClass}`}>
        <div className="cf-sg-nav-scrolling">
          <ul className="usa-sidenav-list">
            { this.props.children }
          </ul>
        </div>
      </div>
    );
  }
}
