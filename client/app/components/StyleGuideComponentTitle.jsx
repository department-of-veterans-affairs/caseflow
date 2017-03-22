import React, { PropTypes } from 'react';
import { GithubIcon } from './RenderFunctions';

export default class StyleGuideComponentTitle extends React.Component {
  render() {
    let {
      id,
      link,
      title
    } = this.props;

    let SourceCodeLink = (props) => {
      /* eslint-disable max-len */
      let baseUrl = "https://github.com/department-of-veterans-affairs/caseflow/blob/master/client/app/containers/StyleGuide/";
      /* eslint-enable max-len */

      return <span>
        <a className="usa-button" href={baseUrl + props.link} target="_blank">
          <GithubIcon /> View Source Code
        </a>
      </span>;
    }

    /* Link is only the name of the file that you want to link to in the
    Style Guide (aka StyleGuideModal.jsx)*/
    return <div className="usa-width-one-whole">
      <div className="cf-push-left">
        <h2 id={id}>{title}</h2>
      </div>

      <div className="cf-push-right">
        <SourceCodeLink link={link} />
      </div>
    </div>;
  }
}

StyleGuideComponentTitle.props = {
  id: PropTypes.string.isRequired,
  link: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired
};
