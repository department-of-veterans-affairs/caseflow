import React from 'react';
import NavLink from './NavLink';

// mostly copy pasted this answer from Stack Overflow: http://stackoverflow.com/a/33555276

export default class StickyNav extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      className: "cf-sg-nav-not-scrolling",
    };
    this.handleScroll = this.handleScroll.bind(this);
  }

  componentDidMount = () => {
    window.addEventListener('scroll', this.handleScroll);
  }

  componentWillUnmount = () => {
    window.removeEventListener('scroll', this.handleScroll);
  }

  handleScroll = () => {
    // Nav bar will attach to top of page if the user scrolls down by 100px
    if (window.scrollY > 100) {
      this.setState({
        className: "cf-sg-nav-scrolling"
      });
    } else if (window.scrollY < 100) {
      this.setState({
        className: "cf-sg-nav-not-scrolling"
      });
    }
  }

  //TODO(marian): add toggle for nav bar to float right for nice dazzler

  render() {
    return (
      <div className={this.state.className}>
        <div className="cf-push-left cf-sg-nav">
          <ul className="usa-sidenav-list">
            { this.props.children }
          </ul>
        </div>
      </div>
    );
  }
  }
