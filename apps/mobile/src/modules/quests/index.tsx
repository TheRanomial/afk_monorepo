import {useNavigation} from '@react-navigation/native';
import {useState} from 'react';
import {KeyboardAvoidingView, ScrollView, Text, View, ActivityIndicator} from 'react-native';
import {SafeAreaView} from 'react-native-safe-area-context';

import {TextButton} from '../../components';
import {Swap} from '../../components/Swap';
import TabSelector from '../../components/TabSelector';
import {TOKENSMINT} from '../../constants/tokens';
import {useStyles} from '../../hooks';
import {WalletOnboarding} from '../Onboard/wallet';
import {MainStackNavigationProps} from '../../types';
import {SelectedTab, TABS_NAMESERVICE, TABS_ONBOARDING_WALLET, TABS_QUESTS} from '../../types/tab';
import {CashuWalletView} from '../CashuWallet';
import {LightningNetworkWalletView} from '../Lightning';
import stylesheet from './styles';
import {FormComponent} from './form';
import {NameCard} from '../../components/NameCard/nameCard';
import {useAccount} from '@starknet-react/core';
import {useNamesList} from '../../hooks/nameservice/useNamesList';
import {NamesList} from '../../components/NamesList';

export const QuestsComponent: React.FC = () => {
  const styles = useStyles(stylesheet);
  const [selectedTab, setSelectedTab] = useState<SelectedTab | undefined>(
    SelectedTab.DYNAMIC_GENERAL,
  );

  const navigation = useNavigation<MainStackNavigationProps>();
  const handleTabSelected = (tab: string | SelectedTab, screen?: string) => {
    setSelectedTab(tab as any);
    // if (screen) {
    //   navigation.navigate(screen as any);
    // }
  };

  const {account} = useAccount();

  const renderContent = () => {
    const {names, isLoading} = useNamesList();

    console.log('NameserviceComponent state:', {
      selectedTab,
      isLoading,
      namesCount: names.length,
      names,
    });

    switch (selectedTab) {
      case SelectedTab.DYNAMIC_GENERAL:
        return (
          <View style={styles.content}>
            <FormComponent />
          </View>
        );
      case SelectedTab.ALL_QUESTS:
        console.log('Rendering All Names tab, count:', names.length);
        return (
          <View style={styles.content}>
            <Text style={styles.text}>All quests</Text>
            {isLoading ? (
              <ActivityIndicator size="large" />
            ) : names.length === 0 ? (
              <Text style={styles.text}>No names found</Text>
            ) : (
              <NamesList names={names} isLoading={isLoading} />
            )}
          </View>
        );
      case SelectedTab.DYNAMIC_OWNED:
        const ownedNames = names.filter(
          (name) => name.owner.toLowerCase() === account?.address?.toLowerCase(),
        );
        console.log('Rendering Your Quests tab:', {
          accountAddress: account?.address,
          ownedNamesCount: ownedNames.length,
          ownedNames,
        });
        return (
          <View style={styles.content}>
            <Text style={styles.text}>Your quest claimed</Text>
            {isLoading ? (
              <ActivityIndicator size="large" />
            ) : names.length === 0 ? (
              <Text style={styles.text}>No names found</Text>
            ) : (
              <NamesList names={ownedNames} isLoading={isLoading} />
            )}
          </View>
        );
      default:
        return <FormComponent />;
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView>
        <KeyboardAvoidingView behavior="padding" style={styles.content}>
          <TabSelector
            activeTab={selectedTab}
            handleActiveTab={handleTabSelected}
            buttons={TABS_QUESTS}
            addScreenNavigation={false}
          />
          <SafeAreaView edges={['bottom', 'left', 'right']} style={styles.content}>
            {renderContent()}
          </SafeAreaView>
        </KeyboardAvoidingView>
      </ScrollView>
    </View>
  );
};
