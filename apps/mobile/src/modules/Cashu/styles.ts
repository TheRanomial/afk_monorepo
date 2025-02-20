import {Dimensions, Platform, StatusBar} from 'react-native';

import {Spacing, ThemedStyleSheet, Typography} from '../../styles';

export default ThemedStyleSheet((theme) => ({
  // invoices
  invoicesListContainer: {
    display: 'flex',
  },
  invoiceContainer: {
    paddingVertical: 10,
    display: 'flex',
    flexDirection: 'row',
  },
  tableHeadersContainer: {
    display: 'flex',
    flexDirection: 'row',
    paddingBottom: 3,
    borderBottomWidth: 2,
    borderColor: theme.colors.primary,
    marginTop: 15,
  },
  tableHeading: {
    fontWeight: 'bold',
    fontSize: 14,
    color: theme.colors.text,
  },
  amountColumn: {
    width: '40%',
  },
  actionsColumn: {
    width: '60%',
    justifyContent: 'flex-end',
    display: 'flex',
    flexDirection: 'row',
    gap: 10,
  },
  amountText: {
    color: theme.colors.text,
  },
  invoicesActionButton: {
    backgroundColor: 'transparent',
  },
  invoiceModalContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  invoiceModalContent: {
    width: Dimensions.get('window').width * 0.85,
    maxHeight: Dimensions.get('window').height * 0.8,
    maxWidth: 400,
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
    padding: 20,
  },
  invoiceModalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginBottom: 20,
    textAlign: 'center',
    borderBottomWidth: 1,
    borderColor: theme.colors.primary,
    paddingBottom: 10,
  },
  invoiceModalTextAmount: {
    fontSize: 16,
    color: theme.colors.text,
    marginBottom: 5,
    textAlign: 'center',
  },
  invoiceModalTextTime: {
    fontSize: 12,
    color: theme.colors.text,
    marginBottom: 5,
    textAlign: 'center',
  },
  invoiceModalTextState: {
    fontWeight: 'bold',
    color: theme.colors.errorDark,
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 5,
  },
  invoiceModalActionsContainer: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
  },
  invoiceModalActionButton: {
    backgroundColor: 'transparent',
    paddingBottom: 0,
  },
  invoiceModalActionButtonText: {
    color: theme.colors.text,
  },

  // history
  txListContainer: {
    display: 'flex',
  },
  txContainer: {
    paddingVertical: 10,
    display: 'flex',
    flexDirection: 'row',
  },
  txDirectionColumn: {
    width: '10%',
  },
  txAmountColumn: {
    width: '40%',
    alignItems: 'flex-end',
  },
  dirText: {
    textTransform: 'uppercase',
    fontSize: 10,
    fontWeight: 'bold',
  },
  dirOutText: {
    color: theme.colors.errorDark,
  },
  dirInText: {
    color: theme.colors.primary,
  },
  txActionsColumn: {
    width: '50%',
    justifyContent: 'flex-end',
    display: 'flex',
    flexDirection: 'row',
    gap: 10,
  },
  txActionButton: {
    backgroundColor: 'transparent',
  },
  txModalContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  txModalContent: {
    width: Dimensions.get('window').width * 0.85,
    maxHeight: Dimensions.get('window').height * 0.8,
    maxWidth: 400,
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
    padding: 20,
  },
  txModalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginBottom: 20,
    textAlign: 'center',
    borderBottomWidth: 1,
    borderColor: theme.colors.primary,
    paddingBottom: 10,
  },
  txModalTextAmount: {
    fontSize: 16,
    color: theme.colors.text,
    marginBottom: 5,
    textAlign: 'center',
  },
  txModalTextTime: {
    fontSize: 12,
    color: theme.colors.text,
    marginBottom: 5,
    textAlign: 'center',
  },
  txModalTextState: {
    fontWeight: 'bold',
    color: theme.colors.errorDark,
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 5,
  },
  txModalActionsContainer: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
  },
  txModalActionButton: {
    backgroundColor: 'transparent',
    paddingBottom: 0,
  },
  txModalActionButtonText: {
    color: theme.colors.text,
  },

  container: {
    // flex:1,
    width: '100%',
    // maxWidth: 500,
    padding: Spacing.medium,
    borderRadius: 10,
    // position: 'relative',
    flex: 1,
    // backgroundColor: theme.colors.background,
    backgroundColor: 'transparent',
    color: theme.colors.text,
  },
  tabSelector: {
    // flex:1,
    // maxWidth: 500,
    padding: Spacing.medium,
    borderRadius: 10,
    // position: 'relative',
    flex: 1,
    flexDirection: 'row',
    // backgroundColor: theme.colors.background,
    backgroundColor: theme.colors.surface,
    color: theme.colors.text,
  },
  safeArea: {
    flex: 1,
    backgroundColor: theme.colors.background,
    paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0,
  },
  scrollView: {
    flex: 1,
    height: '95%',
    // flexGrow: 1,
    overflow: 'scroll',
    backgroundColor: 'transparent',
  },
  card: {
    backgroundColor: theme.colors.surface,
    borderRadius: 10,
    padding: Spacing.medium,
    marginBottom: Spacing.medium,
    shadowColor: theme.colors.shadow,
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    color: theme.colors.text,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: Spacing.medium,
    color: theme.colors.text,
  },
  content: {
    borderRadius: 999,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.small,
    backgroundColor: theme.colors.transparent,
    height: 56,
    marginBottom: Spacing.medium,
    color: theme.colors.text,
  },
  input: {
    borderWidth: 1,
    borderRadius: 5,
    borderColor: theme.colors.inputBorder,
    flex: 1,
    height: 80,
    paddingHorizontal: 20,
    paddingVertical: 15,
    color: theme.colors.inputText,
    backgroundColor: theme.colors.inputBackground,
    fontSize: 15,
    marginBottom: 15,
    width: '80%',
    marginHorizontal: 20,
  },
  button: {
    backgroundColor: theme.colors.primary,
    padding: Spacing.medium,
    borderRadius: 20,
    alignItems: 'center',
    marginTop: Spacing.small,
    marginBottom: Spacing.small,
  },
  pasteButton: {
    backgroundColor: 'transparent',
    borderRadius: 30,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.primary,
    paddingHorizontal: Spacing.medium,
    paddingVertical: Spacing.xsmall,
  },
  pasteButtonText: {
    color: theme.colors.primary,
    fontWeight: 'bold',
  },
  buttonText: {
    color: theme.colors.onPrimary,
    fontWeight: 'bold',
  },
  disabledButton: {
    backgroundColor: theme.colors.primary,
  },
  orText: {
    textAlign: 'center',
    marginVertical: Spacing.small,
    color: theme.colors.text,
    fontWeight: 'bold',
  },
  text: {
    color: theme.colors.text,
    marginTop: 5,
    marginBottom: 5,
    textAlign: 'center',
    fontWeight: 'bold',
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    backgroundColor: theme.colors.surface,
    padding: Spacing.large,
    marginTop: 'auto',
    borderRadius: 10,
    width: '100%',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: Spacing.medium,
    color: theme.colors.text,
  },
  closeButton: {
    marginTop: Spacing.medium,
    alignItems: 'center',
  },
  closeButtonText: {
    color: theme.colors.primary,
    fontWeight: 'bold',
  },
  errorText: {
    marginTop: 3,
    color: theme.colors.errorDark,
  },

  //Wallet Info
  walletContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: 10,
    padding: Spacing.medium,
    marginBottom: Spacing.medium,
    shadowColor: theme.colors.shadow,
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    width: '100%',
  },
  infoSection: {
    marginBottom: Spacing.medium,
  },
  paymentSection: {
    marginBottom: Spacing.medium,
  },
  zapSection: {
    alignItems: 'center',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: theme.colors.text,
    marginBottom: Spacing.small,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: Spacing.small,
  },
  infoLabel: {
    ...Typography.regular,
    color: theme.colors.textSecondary,
  },
  infoValue: {
    ...Typography.semiBold,
    color: theme.colors.text,
  },
  paymentRequest: {
    marginBottom: Spacing.small,
  },
  paymentRequestLabel: {
    ...Typography.regular,
    color: theme.colors.textSecondary,
    marginBottom: Spacing.xsmall,
  },
  paymentRequestValue: {
    ...Typography.regular,
    color: theme.colors.text,
    backgroundColor: theme.colors.messageCard,
    padding: Spacing.small,
    borderRadius: 5,
  },

  zapButton: {
    backgroundColor: theme.colors.secondary,
    padding: Spacing.medium,
    borderRadius: 999,
    alignItems: 'center',
    width: '100%',
  },

  paymentStatus: {
    ...Typography.regular,
    color: theme.colors.text,
    textAlign: 'center',
  },

  banner: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    border: `1px solid ${theme.colors.divider}`,
    backgroundColor: theme.colors.surface,
    borderRadius: 10,
    gap: 12,
    padding: 12,
  },
  bannerText: {
    color: theme.colors.text,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  bannerButtonsContainer: {
    display: 'flex',
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginTop: 20,
    justifyContent: 'center',
  },
  actionsContainer: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    marginTop: 20,
  },
  actionButtonsContainer: {
    // display: 'flex',
    // flexDirection: 'row',
    // flexWrap: 'wrap',
    // gap: 15,
    // marginTop: 20,
    // marginBottom: 20,
    // justifyContent: 'center',
    width: '100%',
  },
  actionButton: {
    flex: 1,
    maxWidth: '40%',
    backgroundColor: theme.colors.primary,
  },
  actionButtonText: {
    color: theme.colors.white,
  },
  qrButton: {
    backgroundColor: 'transparent',
    marginTop: Spacing.small,
    marginBottom: Spacing.small,
  },
  moreButton: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  moreButtonIcon: {
    transform: 'rotate(270deg)',
    marginLeft: 10,
  },
  lessButtonIcon: {
    transform: 'rotate(90deg)',
    marginLeft: 10,
  },
  balanceContainer: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 15,
  },
  balanceTitle: {
    fontSize: 20,
    fontWeight: 600,
    color: theme.colors.text,
  },
  balance: {
    fontSize: 40,
    fontWeight: 900,
    color: theme.colors.primary,
  },
  currencyButton: {
    borderRadius: 20,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: theme.colors.text,
  },
  currencyButtonText: {
    color: theme.colors.text,
  },
  activeMintText: {
    fontSize: 12,
    color: theme.colors.text,
  },
  tabsContainer: {
    maxWidth: '100%',
  },
  tabs: {
    backgroundColor: 'transparent',
    color: theme.colors.text,
    borderRadius: 0,
    width: '30%',
  },
  active: {
    borderBottomWidth: 2,
    borderColor: theme.colors.primary,
  },
  tabContentContainer: {
    padding: 10,
  },
  tabTitle: {
    fontWeight: 'bold',
    fontSize: 14,
    marginBottom: 10,
    color: theme.colors.text,
  },
  titleMargin: {
    marginTop: 20,
  },
  tabSubtitle: {
    fontSize: 12,
    color: theme.colors.text,
  },
  mint: {
    flexDirection: 'row',
    gap: 15,
    alignItems: 'center',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderColor: theme.colors.divider,
    maxWidth: '100%',
  },
  mintContentContainer: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    flex: 1,
  },
  textsContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: 5,
  },
  title: {
    fontSize: 12,
    color: theme.colors.text,
  },
  unitsContainer: {
    display: 'flex',
    flexDirection: 'row',
    gap: 5,
  },
  unit: {
    paddingVertical: 3,
    paddingHorizontal: 6,
    borderRadius: 10,
    backgroundColor: theme.colors.primary,
    color: theme.colors.text,
  },
  radioOuter: {
    height: 24,
    width: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioOuterSelected: {
    borderColor: theme.colors.primary,
  },
  radioInner: {
    height: 12,
    width: 12,
    borderRadius: 6,
    backgroundColor: theme.colors.primary,
  },
  mintActionsContainer: {
    display: 'flex',
    flexDirection: 'row',
    gap: 10,
    height: '100%',
    alignItems: 'center',
  },
  addMintInput: {
    borderWidth: 1,
    borderRadius: 999,
    borderColor: theme.colors.inputBorder,
    flex: 1,
    height: '100%',
    color: theme.colors.inputText,
    backgroundColor: theme.colors.inputBackground,
    fontSize: 12,
    marginTop: 10,
    padding: 8,
  },
  qrButtonSmall: {
    padding: 0,
    display: 'flex',
    alignItems: 'center',
  },
  addMintBtn: {
    marginTop: 15,
    backgroundColor: theme.colors.primary,
    padding: 10,
  },
  addMintBtnText: {
    color: theme.colors.white,
    fontSize: 14,
  },
  newMintError: {
    marginTop: 5,
    color: theme.colors.errorDark,
    fontWeight: 'bold',
  },
  noDataContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: 15,
    alignItems: 'center',
    marginTop: 15,
  },
  noDataText: {
    color: theme.colors.text,
    textAlign: 'center',
    fontSize: 14,
    fontWeight: 'bold',
  },
  label: {
    fontSize: 14,
    marginBottom: 8,
    color: '#333',
  },

  picker: {
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
    marginBottom: 16,
  },
  confirmContainer: {
    marginVertical: 20,
  },
  confirmText: {
    fontSize: 16,
    marginBottom: 16,
  },
  buttonContainer: {
    flexDirection: 'column',
    gap: 15,
  },
  // send and receive modals
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    position: 'relative',
    alignItems: 'center',
    width: '100%',
  },
  modalTabsMainContainer: {
    backgroundColor: theme.colors.background,
    width: '100%',
    alignItems: 'center',
    maxWidth: 400,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    position: 'absolute',
    bottom: 0,
  },
  modalTabContentContainer: {
    backgroundColor: theme.colors.surface,
    width: '100%',
    alignItems: 'center',
    maxWidth: 400,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
    maxHeight: '95%',
    overflow: 'scroll',
    paddingBottom: 20,
    position: 'relative',
  },
  tabContainer: {
    flexDirection: 'column',
    width: '80%',
    marginBottom: 30,
  },
  modalTabsTitle: {
    padding: 20,
    textTransform: 'uppercase',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    color: theme.colors.inputText,
  },
  modalTabContentTitle: {
    padding: 20,
    textTransform: 'uppercase',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    color: theme.colors.inputText,
  },
  modalTabLabel: {
    marginBottom: 2,
    textTransform: 'uppercase',
    fontSize: 12,
    fontWeight: 'bold',
    color: theme.colors.inputText,
    textAlign: 'left',
    width: '80%',
  },
  tab: {
    backgroundColor: theme.colors.primary,
    borderRadius: 50,
    flex: 1,
    padding: 10,
    marginBottom: 10,
  },
  tabText: {
    fontSize: 18,
    color: theme.colors.white,
    textAlign: 'center',
    fontWeight: 'medium',
  },
  modalActionButton: {
    marginBottom: 20,
    marginTop: Spacing.small,
    backgroundColor: theme.colors.primary,
  },
  modalActionButtonText: {
    color: theme.colors.white,
  },

  //mint info modal
  mintInfoModalMainContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  mintInfoModalContent: {
    width: Dimensions.get('window').width * 0.85,
    maxHeight: Dimensions.get('window').height * 0.8,
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
    maxWidth: 450,
    position: 'relative',
    paddingVertical: 30,
    paddingHorizontal: 10,
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
  },
  mintInfoModalText: {
    color: theme.colors.text,
    textAlign: 'center',
  },
  mintInfoModalTitle: {
    fontWeight: 'bold',
    fontSize: 20,
    marginTop: 25,
    marginBottom: 20,
  },
  mintInfoModalDescription: {
    fontSize: 12,
  },
  mintInfoModalVersion: {
    fontSize: 10,
  },
  mintInfoModalNuts: {
    fontSize: 10,
  },
}));
