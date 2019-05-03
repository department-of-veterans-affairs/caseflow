import { css } from 'glamor';

const grayLineStyling = css({
  width: '5px',
  background: COLORS.GREY_LIGHT,
  margin: 'auto',
  position: 'absolute',
  top: '30px',
  left: '49.5%',
  bottom: 0
});

const grayLineTimelineStyling = css(grayLineStyling, { left: '9%',
  marginLeft: '12px',
  top: '39px' });

const greyDotAndlineStyling = css({ top: '25px' });

const taskContainerStyling = css({
  border: 'none',
  verticalAlign: 'top',
  padding: '3px',
  paddingBottom: '3rem'
});

const taskInfoWithIconContainer = css({
  textAlign: 'center',
  border: 'none',
  padding: '0 0 0 0',
  position: 'relative',
  verticalAlign: 'top',
  width: '15px'
});

const taskTimeContainerStyling = css(taskContainerStyling, { width: '20%' });

const taskInformationContainerStyling = css(taskContainerStyling, { width: '25%' });

const taskActionsContainerStyling = css(taskContainerStyling, { width: '50%' });

const taskTimeTimelineContainerStyling = css(taskContainerStyling, { width: '40%' });

const taskInformationTimelineContainerStyling =
  css(taskInformationContainerStyling, { align: 'left',
    width: '50%',
    maxWidth: '235px' });

const taskInfoWithIconTimelineContainer =
  css(taskInfoWithIconContainer, { textAlign: 'left',
    marginLeft: '5px',
    width: '10%',
    paddingLeft: '0px' });

const greyDotStyling = css({ paddingLeft: '6px' });

const greyDotTimelineStyling = css({ padding: '0px 0px 0px 5px' });

export default {
  grayLineStyling,
  grayLineTimelineStyling,
  greyDotAndlineStyling,
  taskContainerStyling,
  taskInfoWithIconContainer,
  taskTimeContainerStyling,
  taskInformationContainerStyling,
  taskActionsContainerStyling,
  taskTimeTimelineContainerStyling,
  taskInformationTimelineContainerStyling,
  taskInfoWithIconTimelineContainer,
  greyDotStyling,
  greyDotTimelineStyling
}
