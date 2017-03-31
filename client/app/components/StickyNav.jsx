import React from 'react';
import NavLink from './NavLink';

// mostly copy pasted this answer from Stack Overflow: http://stackoverflow.com/a/33555276

export default class StickyNav extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      className: "cf-sg-nav-not-scrolling",
      current: false,
      scrollingLock: false
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
    if (window.scrollY > 100) {
      this.setState({
        className: "cf-sg-nav-scrolling",
        scrollingLock: true
      });
    } else if (window.scrollY < 100) {
      this.setState({
        className: "cf-sg-nav-not-scrolling",
        scrollingLock: false
      });
    }
  }

  render() {
    return (
      <div className={this.state.className}>
        { this.props.children }
      </div>
    );
  }
  }
