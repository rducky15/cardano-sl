module Explorer.Types.State where

import Control.Monad.Eff.Exception (Error)
import Control.SocketIO.Client (Socket)
import Data.DateTime (DateTime)
import Data.Generic (class Generic, gShow)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Data.Tuple (Tuple)
import Explorer.Api.Types (SocketSubscription, SocketSubscriptionData)
import Explorer.I18n.Lang (Language)
import Explorer.Routes (Route)
import Explorer.Util.Config (SyncAction)
import Network.RemoteData (RemoteData)
import Pos.Explorer.Web.ClientTypes (CAddress, CAddressSummary, CBlockEntry, CBlockSummary, CTxBrief, CTxEntry, CTxSummary)
import Prelude (class Eq, class Ord, class Show)
import Waypoints (Waypoint)

-- Add all State types here to generate lenses from it

type State =
    { lang :: Language
    , route :: Route
    , socket :: SocketState
    , syncAction :: SyncAction
    , viewStates :: ViewStates
    , latestBlocks :: RemoteData Error CBlockEntries
    , currentBlockSummary :: RemoteData Error CBlockSummary
    , currentBlockTxs :: RemoteData Error CTxBriefs
    , currentTxSummary :: RemoteData Error CTxSummary
    , latestTransactions :: RemoteData Error CTxEntries
    , currentCAddress :: CAddress
    , currentAddressSummary :: RemoteData Error CAddressSummary
    , currentBlocksResult :: RemoteData Error CBlockEntries
    , errors :: Errors
    , loading :: Boolean
    , now :: DateTime
    }

data Search
    = SearchAddress
    | SearchTx
    | SearchTime

derive instance gSearch :: Generic Search
instance showSearch :: Show Search where
    show = gShow
derive instance eqSearch :: Eq Search

type SearchEpochSlotQuery = Tuple (Maybe Int) (Maybe Int)

type SocketState =
    { connected :: Boolean
    , connection :: Maybe Socket
    , subscriptions :: SocketSubscriptionItems
    }

type SocketSubscriptionItems = Array SocketSubscriptionItem

newtype SocketSubscriptionItem = SocketSubscriptionItem
    { socketSub :: SocketSubscription
    , socketSubData :: SocketSubscriptionData
    }

derive instance gSocketSubscriptionItem :: Generic SocketSubscriptionItem
derive instance ntSocketSubscriptionItem :: Newtype SocketSubscriptionItem _
derive instance eqSocketSubscriptionItem :: Eq SocketSubscriptionItem

data DashboardAPICode = Curl | Node | JQuery
derive instance eqDashboardAPICode :: Eq DashboardAPICode
derive instance ordDashboardAPICode :: Ord DashboardAPICode

type CBlockEntries = Array CBlockEntry

type CTxEntries = Array CTxEntry
type CTxBriefs = Array CTxBrief

type Errors = Array String

type ViewStates =
    { globalViewState :: GlobalViewState
    , dashboard :: DashboardViewState
    , addressDetail :: AddressDetailViewState
    , blockDetail :: BlockDetailViewState
    , blocksViewState :: BlocksViewState
    }

type GlobalViewState =
    { gViewMobileMenuOpenend :: Boolean
    , gViewSearchInputFocused :: Boolean
    , gViewSelectedSearch :: Search
    , gViewSearchQuery :: String
    , gViewSearchTimeQuery :: SearchEpochSlotQuery
    , gWaypoints :: WaypointItems
    }

type WaypointItems = Array WaypointItem

newtype WaypointItem = WaypointItem
    { wpInstance :: Waypoint
    , wpRoute :: Route
    }

type DashboardViewState =
    { dbViewBlocksExpanded :: Boolean
    , dbViewBlockPagination :: PageNumber
    , dbViewMaxBlockPagination :: RemoteData Error PageNumber
    , dbViewLoadingBlockPagination :: Boolean
    , dbViewBlockPaginationEditable :: Boolean
    , dbViewTxsExpanded :: Boolean
    , dbViewSelectedApiCode :: DashboardAPICode
    }

type BlockDetailViewState =
    { blockTxPagination :: PageNumber
    , blockTxPaginationEditable :: Boolean
    }

type AddressDetailViewState =
    { addressTxPagination :: PageNumber
    , addressTxPaginationEditable :: Boolean
    }

type BlocksViewState =
    { blsViewPagination :: PageNumber
    , blsViewPaginationEditable :: Boolean
    }

newtype PageNumber = PageNumber Int
derive instance gPageNumber :: Generic PageNumber
derive instance ntPageNumber :: Newtype PageNumber _
derive instance eqPageNumber :: Eq PageNumber
derive instance oPageNumber :: Ord PageNumber
instance showPageNumber :: Show PageNumber where
    show = gShow

newtype PageSize = PageSize Int

-- TODO (jk) CCurrency should be generated by purescript-bridge later
data CCurrency
    = ADA
    | BTC
    | USD
