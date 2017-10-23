import React from 'react';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideHorizontalLine extends React.Component {
  render = () => {
    return <div>
      <StyleGuideComponentTitle
        title="Horizontal Line"
        id="horizontal_line"
        link="StyleGuideHorizontalLine.jsx"
        isSubsection={true}
      />

      <p>The horizontal line helps provide clarity and improve legibility
  for users by separating different sections or UI components on a page.
  Caseflow horizontal lines should always be light grey and have 30 px
  of space between the bottom of the section or component and the top of the horizontal line.</p>

      <div className="cf-help-divider"></div>
    </div>;
  }
}
