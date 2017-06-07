import React from 'React';
import DropDown from '../components/DropDown';

export default class Login extends React.PureComponent {
  render() {
    return <div className="cf-app-segment">
    <h1>Welcome to Caseflow!</h1>
    <p>Please select the regional office you are logging in from.</p>

    <DropDown name="RO selector" options={[]} />

    <div>
      <button type="submit">Login</button>
    </div>
  </div>;
  }
}