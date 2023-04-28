 import Wearables from 0xe81193c424cfd3fb
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import Profile from 0x097bafa4e0b48eef
import FungibleToken from 0xf233dcee88fe0abe
import FindRelatedAccounts from 0x097bafa4e0b48eef

//Initialize a users storage slots for character
transaction(wallet: String, network: String, address: String) {
    var relatedAccounts : &FindRelatedAccounts.Accounts?
    prepare(account: AuthAccount) {

        let wearableCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Wearables.CollectionPublicPath)
        if !wearableCap.check() {
            account.save<@NonFungibleToken.Collection>( <- Wearables.createEmptyCollection(), to: Wearables.CollectionStoragePath)
            account.link<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPublicPath,
                target: Wearables.CollectionStoragePath
            )
            account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPrivatePath,
                target: Wearables.CollectionStoragePath
            )
        }

        self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
            self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }

        let cap = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
        if !cap.check() {
            account.unlink(FindRelatedAccounts.publicPath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
        }

        let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
        if !profileCap.check() {
            let profile <-Profile.createUser(name:account.address.toString(), createdAt: "Doodles")

            account.save(<-profile, to: Profile.storagePath)
            account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
            account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
        }
    }

    execute{
        self.relatedAccounts!.addRelatedAccount(name: wallet, network: network, address: address)
    }
}
