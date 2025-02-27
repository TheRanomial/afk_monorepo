import {Spacing, ThemedStyleSheet} from '../../styles';

export default ThemedStyleSheet((theme) => ({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
    paddingVertical: Spacing.xxxsmall,
    paddingHorizontal: Spacing.normal,
  },
  text: {
    color: theme.colors.text,
    marinBottom: Spacing.xxxlarge,
    textAlign: 'center',
  },

  flatListContent: {
    paddingHorizontal: Spacing.pagePadding,
    paddingVertical: Spacing.medium,
  },

  modalContent: {
    paddingTop: '20%',
    flexDirection: 'column',
    gap: 30,
  },
  modalContents: {
    paddingTop: '6%',
    flexDirection: 'column',
    gap: 30,
  },
  separator: {
    height: 1,
    backgroundColor: theme.colors.divider,
  },

  tip: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: theme.colors.surface,
    padding: Spacing.xsmall,
    borderRadius: 8,
    gap: Spacing.xsmall,
  },
  tipInfo: {
    gap: Spacing.xxsmall,
  },
  token: {
    flex: 1,
    flexDirection: 'row',
    gap: Spacing.xsmall,
  },

  senderInfo: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: Spacing.medium,
  },
  sender: {
    flex: 1,
  },

  buttonIndicator: {
    marginRight: Spacing.xsmall,
  },
  createPostButton: {
    position: 'absolute',
    bottom: Spacing.large,
    right: Spacing.pagePadding,
  },
  modal: {
    // backgroundColor: theme.colors.background,
    // padding: Spacing.normal,
    // borderRadius: 8,
    height: '100%',
  },
}));
