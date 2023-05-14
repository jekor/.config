-- -*- compile-command: "home-manager switch" -*-

import qualified Data.Map as M
import XMonad (XConfig(..), xmonad, mod4Mask)
import XMonad.Config (def)
import XMonad.Core (spawn)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (manageDocks, avoidStruts)
import XMonad.Hooks.ManageHelpers (doCenterFloat)
import XMonad.Layout ((|||), Full(Full), Tall(Tall), ChangeLayout(NextLayout), Resize(Expand, Shrink))
import XMonad.Layout.Fullscreen (fullscreenFull)
import XMonad.Layout.Grid (Grid(Grid))
import XMonad.Layout.GridVariants (SplitGrid(SplitGrid), Orientation(L))
import XMonad.Layout.NoBorders (noBorders, smartBorders)
import XMonad.ManageHook (className, (=?), (-->), composeAll)
import XMonad.Layout.PerScreen (ifWider)
import XMonad.Layout.PerWorkspace (onWorkspace, onWorkspaces)
import XMonad.Layout.TwoPane (TwoPane(TwoPane))
import XMonad.Operations (sendMessage, withFocused, windows)
import qualified XMonad.StackSet as SS
import XMonad.Util.EZConfig (additionalKeysP, removeKeysP)

chords = [ ("M-M1-e", sendMessage Expand)
         , ("M-M1-s", sendMessage Shrink)
         , ("M-l", sendMessage NextLayout)
         , ("M-S-f", withFocused toggleFloat)
         ] <> shortcuts
 where toggleFloat w = windows (\s -> if M.member w (SS.floating s)
                                        then SS.sink w s
                                        else (SS.float w (SS.RationalRect (1/3) (1/4) (1/2) (4/5)) s))

-- Some chords are mapped by xbindkeys or used by the input method.
reservedChords = [ "M-<Space>" ]

spaces = ["emacs", "browser", "term", "files", "comms", "client", "scratch", "monitor"]

layouts = onWorkspace "emacs" (noBorders Full)
        $ onWorkspace "browser" (noBorders (fullscreenFull (Full ||| twoPane)))
        $ onWorkspace "term" (noBorders (fullscreenFull (SplitGrid L 1 1 (2/5) (3/2) (10/100) ||| Grid ||| tall ||| Full)))
        $ onWorkspaces ["files", "comms"] (noBorders (fullscreenFull (twoPane ||| Full ||| tall)))
        $ noBorders (fullscreenFull (Full ||| tall))
 where tall = Tall 1 (3/100) (1/2)
       twoPane = TwoPane (3/100) (1/2)

main = do
  xmonad (ewmh def `removeKeysP` (fmap fst chords <> reservedChords) `additionalKeysP` chords)
    { modMask = mod4Mask
    , terminal = "mlterm"
    , manageHook = composeAll [ manageDocks
                              -- xprop | grep CLASS
                              , className =? "mpv" --> doCenterFloat
                              , className =? "Calendar" --> doCenterFloat
                              , manageHook def ]
    , workspaces = spaces
    , layoutHook = avoidStruts $ ifWider 1920 (smartBorders layouts) (noBorders Full)
    , focusedBorderColor = "#4FA9A0"
    }
