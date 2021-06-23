import { formatDocketSwitchRuling } from 'app/queue/docketSwitch/judgeRuling/DocketSwitchRulingContainer';

describe('formatDocketSwitchRuling', () => {
  const context = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit...';

  let disposition = 'granted';

  describe('with granted disposition', () => {
    beforeAll(() => {
      disposition = 'granted';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRuling({
        context,
        disposition,
      });

      expect(res).toMatch(
        new RegExp('I am proceeding with a full switch\\. {2}\\n {2}\\n')
      );
      expect(res).toMatch(
        new RegExp(context)
      );
      expect(res).toMatchSnapshot();
    });
  });

  describe('with partially_granted disposition', () => {
    beforeAll(() => {
      disposition = 'partially_granted';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRuling({
        context,
        disposition,
      });


      expect(res).toMatch(
        new RegExp(
          'I am proceeding with a partial switch\\. {2}\\n {2}\\n'
        )
      );
      expect(res).toMatch(
        new RegExp(context)
      );
      expect(res).toMatchSnapshot();
    });
  });

  describe('with denied disposition', () => {
    beforeAll(() => {
      disposition = 'denied';
    });

    it('properly formats', () => {
      const res = formatDocketSwitchRuling({
        context,
        disposition,
      });

      expect(res).toMatch(
        new RegExp('I am proceeding with a denial\\. {2}\\n {2}\\n')
      );
      expect(res).toMatch(
        new RegExp(context)
      );
      expect(res).toMatchSnapshot();
    });
  });
});
