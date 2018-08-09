// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import Tooltip from '../../components/Tooltip';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions';
import type {
  BasicAppeal
} from '../types/models';
import COPY from '../../../COPY.json';

type Params = {|
  appeal: BasicAppeal
|};

type Props = Params & {|
  externalId: string,
  docs: Array<Object>,
  error: string,
  getNewDocuments: Function
|};

class NewFile extends React.Component<Props> {
  componentDidMount = () => {
    if (!this.props.docs) {
      this.props.getNewDocuments(this.props.externalId);
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <Tooltip id="newfile-tip" text={COPY.NEW_FILE_ICON_TOOLTIP} offset={{ top: '-10px' }}>
        <NewFileIcon />
      </Tooltip>;
    }

    return null;

  }
}

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId || ownProps.appeal.attributes.external_id;
  const documentObject = state.queue.newDocsForAppeal[externalId];

  return {
    externalId,
    docs: documentObject ? documentObject.docs : null,
    error: documentObject ? documentObject.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFile): React.ComponentType<Params>);
