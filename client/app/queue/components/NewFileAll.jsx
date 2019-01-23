// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions';
import type { State } from '../types/state';
import COPY from '../../../COPY.json';

import _ from 'lodash';

type Params = {|
  tasks: Object
|};

type Props = Params & {|
  externalIds: Array<string>,
  documentObjects: Object,
  getNewDocuments: Function
|};

class NewFileAll extends React.Component<Props> {
  componentDidMount = () => {
    this.props.externalIds.forEach((externalId) => {
      if (!this.props.documentObjects[externalId].docs && !this.props.documentObjects[externalId].loading) {
        this.props.getNewDocuments(externalId);
      }
    });
  }

  render = () => {
    // Check to see if there are any new documents for any appeals
    const allDocs = _.filter(_.map(this.props.documentObjects, 'docs'),
      (appealDocs) => appealDocs && appealDocs.length);

    if (allDocs && allDocs.length) {
      return <Tooltip id="newfile-tip" text={COPY.NEW_FILE_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
      </Tooltip>;
    }

    return null;

  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  // Get only the document objects for the give appeal IDs
  const externalIds = _.map(ownProps.tasks, 'externalAppealId');
  const documentObjects = _.pick(state.queue.newDocsForAppeal, externalIds) || {};

  return {
    externalIds,
    documentObjects
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFileAll): React.ComponentType<Params>);
